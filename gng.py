# A python command line interface for
# interacting with a database to view
# and modify existing entries or add
# new entries 

import psycopg2
import sys
from datetime import datetime
import hashlib
import binascii
import os
import getpass

connection_string = "host= '<host url>' user='<username>' password='<password>'" #ideally this would be stored in seperate file
session_user = 0
write_logs = "INSERT INTO change_log (id, member, change_date, table_name) VALUES (%s, %s, %s, %s)"

def current_id(type):
    query = ""
    if type == 'member_id':
        query = "select max(member_id) from members"
    elif type == 'change_log':
        query = "select max(id) from change_log"
    elif type == 'activity_id':
        query = "select max(id) from activities"
    elif type == 'rent_cost':
        query = "select max(id) from rent_cost"
    elif type == 'salary_cost':
        query = "select max(id) from salary_cost"
    elif type == 'activity_cost':
        query = "select max(id) from activity_cost"
    elif type == 'activity_donation':
        query = "select max(id) from activity_donation"
    elif type == 'donor_donation':
        query = "select max(id) from donor_donation"

    dbconn = psycopg2.connect(connection_string)
    cursor = dbconn.cursor()
    cursor.execute(query) 
    num = cursor.fetchone()[0] + 1
    cursor.close()
    dbconn.close()
    return num

def check_input(input, length):
    if len(input) > length:
        return False
    else:
        return True

# When called allows user to create a single new webpage
def add_webpage(campaign_name):
    dbconn = psycopg2.connect(connection_string)
    cursor = dbconn.cursor()

    print("-----Create a new webpage-----")
    print("Enter -QUIT in any field to exit and discard changes")
    new_url = input("Please enter the url for the webpage: ")
    new_title = input("Please enter the title for the webpage: ")
    if (new_url or new_title) == '-QUIT': 
        return
    
    try:
        cursor.execute("INSERT INTO website (webpage_url, webpage_title, date_added) VALUES (%s, %s, %s)", (new_url, new_title, datetime.now()))
    except psycopg2.Error as e:
        print("\nCreate webpage failed, this url is not availible!\n")
        return 'failweb'
    cursor.execute(write_logs, (current_id('change_log'), session_user, datetime.now(), 'website'))
    dbconn.commit()
    try:
        cursor.execute("UPDATE campaigns SET url = %s WHERE name = %s", (new_url, campaign_name))
    except psycopg2.Error as e:
        print("\nFailed to add URL to campaign "+campaign_name+"\n")
        return 'failcamp'
    cursor.execute(write_logs, (current_id('change_log'), session_user, datetime.now(), 'campaigns'))

    dbconn.commit()
    cursor.close()
    dbconn.close()

    return new_url

def view_queries():
    print("Choose Query View:")
    print("[1] What are the titles of websites that Oleg Oragami (member 28) has modified")
    print("[2] Which members participated in the activity of Kayaking to tankers (activity 5)")
    print("[3] What is the average number of campaigns GnG members have participated in")
    print("[4] Find the member id who has participated in the highest number of activities")
    print("[5] Find the emails of all the GnG members who participate in the Save the Sea campaign")
    print("[6] Find the members who have lasted edited more than one different page of the website")
    print("[7] Find members who are participating in campaigns which are still in progress")
    print("[8] Find all volunteer member ids, names and who volunteer on either 1-2")
    print("[9] Find the number of unique members who participate on a campaign")
    print("[10] Find all members who have a higher salary than Kendrick Klooper (member 24)")

    dbconn = psycopg2.connect(connection_string)
    selection =  input("Please select a view: ")
    cursor = dbconn.cursor()

    options = ('1','2','3','4','5','6','7','8','9','10')
    if selection not in options: 
        print("\nInvalid view number\n")
        return

    # Although this looks unsafe, any input not in options list is rejected
    cursor.execute("select * from q"+str(selection))
    results = cursor.fetchall()
    labels = [desc[0] for desc in cursor.description]
    temp = ' | '.join(str(attribute).ljust(20) for attribute in labels)
    print(temp)

    for row in results:
        temp = ' | '.join(str(attribute).ljust(20) for attribute in row)
        print('-' * len(temp))
        print(temp)
        print('-' * len(temp))

    cursor.close()
    dbconn.close()

# Method for creating new campaigns, members and adding new and existing members to the campaign
def modify_campaign():
    print("---Creating a new campaign---")
    campaign_name = input("Please enter a name for the campaign: ")
    if check_input(campaign_name, 20) is False:
        print("Name too long, 20 characters maximum")
        return
    campaign_goal = input("Please enter the goal of the campaign: ")
    if check_input(campaign_goal, 30) is False:
        print("Goal too long, 30 characters maximum")
        return
    campaign_start = input("Please enter the starting date of the campaign \nin the format MM/DD/YEAR HOURS:MINUTES:SECONDS ")

    #Inter into campaigns a new campaign here
    dbconn = psycopg2.connect(connection_string)
    cursor = dbconn.cursor()
    try:
        cursor.execute("INSERT INTO campaigns (name, goal, started_on, completed) VALUES (%s, %s, %s, %s)", (campaign_name, campaign_goal, campaign_start, False))
    except psycopg2.Error as e:
        print("\nCreate campaign failed, the campaign already exists or the date is invalid!\n")
        return
    dbconn.commit()
    
    #Notifying user of status
    view_campaign_status(campaign_name)
    
    print("---Adding participants to campaign---")
    participants = []
    print("Please enter the member id of a participant and press ENTER")
    while True:
        print("ENTER -NEW to create a new member for -DONE when finished")
        temp = input("member_id: ")
        if temp == '-DONE': 
            break
        elif temp == '-NEW': #This adds a new member to the database and associates them with the campaign being created
            new_id = current_id('member_id')
            new_name = input("Name of member: ")
            new_email = input("Email of member: ")
            if check_input(new_name, 25) is False:
                print("Name is too long, maximum 25 characters")
                continue
            if check_input(new_email, 25) is False:
                print("email is too long, maximum 25 characters")
                continue
            try:
                cursor.execute("INSERT INTO members (member_id, name, email, join_date) VALUES (%s, %s, %s, %s)", (new_id, new_name, new_email, datetime.now()))
            except psycopg2.Error as e:
                print("Create member failed since this email is already used by another member")
                continue
            dbconn.commit()
            participants.append(new_id)
        else:
            participants.append(temp)
    
    #This iterates and updates the number of campaigns a participant has been in
    for person in set(participants):
        try:
            cursor.execute("INSERT INTO participates_in_campaign (campaign, member) VALUES (%s, %s)", (campaign_name, person))
        except psycopg2.Error as e:
            print("Failed to add members to participates_in_campaign table")
        find_num_campaigns = "SELECT num_campaigns FROM members WHERE member_id = "+str(person) #Find number of campaigns member has already participated in
        try:
            cursor.execute(find_num_campaigns)
        except psycopg2.Error as e:
            print("Failed to find number of campaigns participated in for member "+str(person)) 
        updated_num = 0
        if cursor.rowcount > 0:
            temp = cursor.fetchone()
            updated_num = temp[0]
        if updated_num is None:
            updated_num = 1
        else:
            updated_num = updated_num + 1
       
        try:
            cursor.execute("UPDATE members SET num_campaigns = %s WHERE member_id = %s", (updated_num, person))
        except psycopg2.Error as e:
            print("Failed to update number of campaigns participated in for member "+str(person))
    dbconn.commit()
    view_campaign_status(campaign_name)

    dbconn.commit()
    cursor.close()
    dbconn.close()

    # Create a webpage for the campaign
    webpage = add_webpage(campaign_name)
    view_campaign_status(campaign_name)

    # Add activites
    will_add = input("Would you like to add activities (yes/no)? ")
    if will_add.lower() == 'yes':
        all_acts = add_activities(campaign_name, webpage)
        view_campaign_status(campaign_name)

    # Add activity costs
    will_cost = input("Would you like to add activity costs (yes/no)? ")
    if will_cost.lower() == 'yes':
        while True:
            add_costs('activity')
            another_cost = input("Would you like to add another activity cost (yes/no)? ")
            if another_cost.lower() != 'yes':
                break
    view_campaign_status(campaign_name)
    print("\n"+campaign_name+" campaign setup complete.\n")
    
# Method for creating new activites associated with a campaign and adding participants
def add_activities(name, new_url):
    dbconn = psycopg2.connect(connection_string)
    cursor = dbconn.cursor()
    activity_list = "\n---Activities---\n"

    while True:
        print("--Create a new activity--")
        new_id = current_id('activity_id')
        new_desc = input("Please enter a short description: ")
        new_date = input("Please enter the date of the activity \nin the format MM/DD/YEAR HOURS:MINUTES:SECONDS ")
        #camp_name = input("Please enter the exact name of the campaign it is a part of")
        new_location = input("Please enter the location of the activity: ")
        #automatically grab website url, maybe website if activity is created during campaign creation
        
        try:
            cursor.execute("INSERT INTO activities (id, description, activity_date, campaign_name, location, completed, url) VALUES (%s, %s, %s, %s, %s, %s, %s)", (new_id, new_desc, new_date, name, new_location, False, new_url))
        except psycopg2.Error as e:
            print("\nFailed to create activity "+new_desc+"!\n")
            continue
        try:
            cursor.execute("INSERT INTO in_campaign (activity_id, campaign_name) VALUES (%s, %s)", (new_id, name))
        except psycopg2.Error as e:
            print("\nFailed to associate "+new_desc+" with the campaign "+name+"!\n")
            continue

        participants = []
        print("Please enter the member id of a participant and press ENTER")
        while True:
            print("ENTER -NEW to create a new member for -DONE when finished")
            temp = input("member_id: ")
            if temp == '-DONE':
                print() 
                break
            else:
                participants.append(temp)
        
        for person in participants:
            try:
                cursor.execute("INSERT INTO participates_in_activity (activity, member) VALUES (%s, %s)", (new_id, person))
            except psycopg2.Error as e:
                print("\nFailed to add "+str(person)+" to the activity id "+str(new_id)+", they might not exist!\n")
                continue
        dbconn.commit()
        activity_list = activity_list+"Activity ID: "+str(new_id)+"\nDescription: "+new_desc+"\nDate: "+str(new_date)+"\nLocation: "+new_location+"\nParticipants: "+', '.join(participants)+"\n\n"
        
        quit_choice = input("Would you like to create another activity? (yes/no) ")
        if quit_choice.lower() != 'yes': 
            break

    cursor.close()
    dbconn.close()
    return activity_list

def view_campaign_status(campaign_name):
    dbconn = psycopg2.connect(connection_string)
    cursor = dbconn.cursor()

    try:
        cursor.execute("select * from campaigns where name = %s", (campaign_name,))
    except psycopg2.Error as e:
        print("\nFailed to retrieve "+campaign_name+" information\n")
    camp_stat = cursor.fetchone()
    print("\n---Campaign Status---\nCampaign: "+camp_stat[0]+"\nGoal: "+camp_stat[1]+"\nStarting Date: "+str(camp_stat[2])+"\n")
    
    try:
        cursor.execute("select member from participates_in_campaign where campaign = %s", (campaign_name,))
    except psycopg2.Error as e:
        print("\nFailed to find participants in "+campaign_name+"\n")
    camp_mems = cursor.fetchall()
    #✓
    
    if camp_mems:
        print("---"+str(len(camp_mems))+" Participants---\nMember IDs: ", end='')
        for member in camp_mems:
            print(str(member[0])+", ", end='')
        print("\n")
    else:
        print("Participants [X]\n")
    
    try:
        cursor.execute("select url from campaigns where name = %s", (campaign_name,))
    except psycopg2.Error as e:
        print("\nFailed to find url for campaign "+campaign_name+"\n")
    camp_web = cursor.fetchone()
    if camp_web:
        if camp_web[0] is None:
            print("Webpage: [X]\n")
        else:
            print("Webpage: "+str(camp_web[0])+"\n")        
    
    try:
        cursor.execute("select * from in_campaign join activities on id = activity_id where in_campaign.campaign_name = %s", (campaign_name,))
    except psycopg2.Error as e:
        print("\nFailed to find activities in camapign "+campaign_name+"\n")
    camp_acts = cursor.fetchall()
    if camp_acts:
        print("---"+str(len(camp_acts))+" Activities---")
        print("Activity ID, Description: ", end='')
        for activity in camp_acts:
            print(str(activity[0])+" "+str(activity[3])+", ", end='')
        print()
    else:
        print("Activities: [X]\n")

    try:
        cursor.execute("select sum(amount) from activity_cost join (select * from in_campaign where campaign_name = %s) as new on new.activity_id = activity_cost.activity_id", (campaign_name,))
    except psycopg2.Error as e:
        print("\nFailed to find sum of all activity costs for campaign "+campaign_name+"\n")
    total_cost = cursor.fetchone()
    if total_cost[0]:
        print("Total campaign cost: $"+str(total_cost[0])+"\n")
    else:
        print("Total campaign cost: [X]\n")

    cursor.close()
    dbconn.close()

def bar_chart(cost_tuple):
    #find largest value
    #find largest label by length
    largest = max(amount for desc, date, amount in cost_tuple)    
    longest_desc = max(len(desc) for desc, date, amount in cost_tuple)
    longest_date = max(len(str(date)) for desc, date, amount in cost_tuple)
    indent = max(longest_desc, longest_date)

    size = largest / 50
    for desc, date, amount in cost_tuple:        
        bars = int(amount / size)
        line = '#' * bars
        if not line:
            line = '⊨'
        print(f'{desc.rjust(indent)} {amount:#4d} {line}')

def finances_table(query, chart, table):
    
    if chart == '1':
        bar_chart(query)

    if table == '1':
        query.insert(0, ['Description', 'Date', 'Amount($)'])
        for row in query:
            temp = '|'.join(str(attribute).ljust(30) for attribute in row)
            print(temp)
            print('-' * len(temp))

def add_costs(choice):
    dbconn = psycopg2.connect(connection_string)
    cursor = dbconn.cursor()
    if choice == 'activity':
        cost_type = '1'
    else:
        print("Is it a:\n[1] Activity Cost\n[2] Salary Cost\n[3] Rent Cost")
        cost_type = input("Choice: ")

    new_id = 0
    activity_id = 0
    employee_id = 0
    rental_name = 0
         
    new_amount = input("Please the dollar amount of cost: ")
    new_description = input("Please enter a description of the cost: ")
    new_date = input("Please enter the date of payment: ")

    if cost_type == '1':
        new_id = current_id('activity_cost')
        activity_id = input("Please enter the Activity ID: ")
        try:
            cursor.execute("insert into activity_cost (id, amount, transaction_date, description, activity_id) values (%s, %s, %s, %s, %s)", (new_id, new_amount, new_date, new_description, activity_id))
        except psycopg2.Error as e:
            print("\nFailed to add "+new_description+"to the activity_costs for activity "+activity_id+"\n")
            return
    elif cost_type =='2':
        new_id = current_id('salary_cost')
        employee_id = input("Please enter the Employee ID: ")
        try:
            cursor.execute("insert into salary_cost (id, amount, transaction_date, description, employee_id) values (%s, %s, %s, %s, %s)", (new_id, new_amount, new_date, new_description, employee_id))
        except psycopg2.Error as e:
            print("\nFailed to add "+new_description+"to the salary costs for employee id "+employee_id+"\n")
    elif cost_type =='3':
        new_id = current_id('rent_cost')
        rental_name = input("Please enter the name of the property: ")
        try:
            cursor.execute("insert into rent_cost (id, amount, transaction_date, description, rental_name) values (%s, %s, %s, %s, %s)", (new_id, new_amount, new_date, new_description, rental_name))
        except psycopg2.Error as e:
            print("\nFailed to add "+new_description+"to the rental costs for the property "+rental_name+"\n")
    dbconn.commit()
    cursor.close()
    dbconn.close()
# Reporting on  fund inflows and outflows needed as group plans events
def finances():
    dbconn = psycopg2.connect(connection_string)
    cursor = dbconn.cursor()
    #all donations: select * from activity_donation union select * from donor_donation;
    #after a date: select sum(amount) from (select * from activity_donation union select * from donor_donation) as foo where transaction_date > '01/01/2018 12:00:00';
    #all costs
    #use the query to select a certain date range that will be selected
    #ask user for time period and show graph or donations and costs
    #compare total donations vs costs for a time period
    #show individual costs or donations for a time period
    while True:
        print("Would you like to\n[1] Compare Costs vs Donations \n[2] View Donations \n[3] View Costs \n[4] Add Costs\n[5] Add Donations\n[6] Go back")
        choice = input("Choice: ")

        query_cost = """from (select id, amount, transaction_date, description, rental_name, NULL as employee_id, NULL as activity_id 
                       from rent_cost 
                       union 
                       (select id, amount, transaction_date, description, NULL as rental_name, employee_id, NULL as activity_id 
                       from salary_cost
                       union
                       select id, amount, transaction_date, description, NULL as rental_name, NULL as employee_id, activity_id 
                       from activity_cost)) as total_costs where transaction_date between %s and %s"""

        query_donation = """from (select * from activity_donation 
                            union select * from donor_donation) 
                            as total_donations where transaction_date between %s and %s"""

        if choice == '1':
            start_date = input("Please enter date for search range start: ")
            end_date = input("Please enter date for search range end: ")
            #date_string = str(start_date) + "' and '" + str(end_date) + "'"

            query_start = "select sum(amount) "
            compare_cost = query_start + query_cost# + date_string
            compare_donation = query_start + query_donation# + date_string

            try:
                cursor.execute(compare_cost, (start_date, end_date))
            except psycopg2.Error as e:
                print("\nFailed find costs during selected dates\n")
            cost_results = cursor.fetchone()

            try:
                cursor.execute(compare_donation, (start_date, end_date))
            except psycopg2.Error as e:
                print("\nFailed to find donations during selected dates\n")
            donation_results = cursor.fetchone()

            print("Total Costs: $"+str(cost_results[0]))
            print("Total Donations: $"+str(donation_results[0]))
    

        elif choice == '2':
            start_date = input("Please enter date for search range start: ")
            end_date = input("Please enter date for search range end: ")
            #date_string = str(start_date) + "' and '" + str(end_date) + "'"
            query_start = "select description, transaction_date, amount "
            detailed_donation = query_start + query_donation# + date_string
            try:
                cursor.execute(detailed_donation, (start_date, end_date))
            except psycopg2.Error as e:
                print("\nFailed to find donations for date range\n")
            donation_results = cursor.fetchall()
            finances_table(donation_results, '1', '1')

        elif choice == '3':
            start_date = input("Please enter date for search range start: ")
            end_date = input("Please enter date for search range end: ")
            #date_string = str(start_date) + "' and '" + str(end_date) + "'"
            query_start = "select description, transaction_date, amount "
            detailed_cost = query_start + query_cost# + date_string
            try:
                cursor.execute(detailed_cost, (start_date, end_date))
            except psycopg2.Error as e:
                print("\nFailed to find costs for date range\n")
            cost_results = cursor.fetchall()
            finances_table(cost_results, '1', '1')
        
        elif choice == '4':
            add_costs('finance')

        elif choice == '5':
            print("Is it a\n[1] Donation from a donor\n[2] Donation from Activity")
            donation_type = input("Choice: ")
            new_id = 0
            donor_id = 0
            activity_id = 0
           
            new_description = input("Please enter the dollar amount of donation: ")
            new_description = input("Please enter a description of the donation: ")
            new_date = input("Please enter the date of donation: ")

            if donation_type == '1':
                new_id = current_id('donor_donation')
                donor_id = input("Please enter the Member ID of the donor: ")
                try:
                    cursor.execute("insert into donor_donation (id, amount, transaction_date, description, donor_id) values (%s, %s, %s, %s, %s)", (new_id, new_amount, new_date, new_description, donor_id))
                except psycopg2.Error as e:
                    print("\nFailed to add donor donation to database\n")
                    return
            elif donation_type =='2':
                new_id = current_id('activity_donation')
                activity_id = input("Please enter the Activity ID: ")
                try:
                    cursor.execute("insert into activity_donation (id, amount, transaction_date, description, activity_id) values (%s, %s, %s, %s, %s)", (new_id, new_amount, new_date, new_description, activity_id))
                except psycopg2.Error as e:
                    print("\nFailed to add activity donation to database\n")
                    return

        elif choice == '6':
            break
        dbconn.commit()

    cursor.close()
    dbconn.close()
#use add_webpage within campaign setup
#website_changes(url, member int, created timestamp) --wait for phase 5
#handling incorrect inputs in python and catching database errors
#prevent adding activity participants who aren't in the associated campaign
#show all options at all steps but have boxes and change x to check as finished

def search_member(mem_id):
    dbconn = psycopg2.connect(connection_string)
    cursor = dbconn.cursor()
    try:
        cursor.execute("select * from members where member_id = %s", (mem_id,))
    except psycopg2.Error as e:
        print("\nFailed to find a member with that id\n")
    mem_info = cursor.fetchone()
    cursor.close()
    dbconn.close()
    return mem_info

def set_pass(password):

    salt = hashlib.sha256(os.urandom(60)).hexdigest().encode('ascii')
    hash_value = binascii.hexlify(hashlib.pbkdf2_hmac('sha512', password.encode('utf-8'), salt, 100000))
    combination = salt + hash_value
    hashed_result = (combination).decode('ascii')
    return hashed_result

def authenticate(stored_password, provided_password):

    #Query for member with email and retrieve hashed password
    salt = stored_password[:64]
    stored_password = stored_password[64:]
    pwdhash = binascii.hexlify(hashlib.pbkdf2_hmac('sha512', provided_password.encode('utf-8'), salt.encode('ascii'), 100000)).decode('ascii')
    if pwdhash == stored_password:
        return True
    else:
        return False

def member_history():
    dbconn = psycopg2.connect(connection_string)
    cursor = dbconn.cursor()
    # Query a member and show list of activities and campaings
    while True:
        print("Please select an action\n[1] Search member history\n[2] Add member annotation\n[3] Add campaign participation annotation\n[4] Add activity participation annotation\n[5] Go back")
        choice = input("Choice: ")

        if choice == '5':
            break
        elif choice == '1':
            member = input("Please enter a member ID: ")
            mem_annotation = search_member(member)
            try:
                cursor.execute("select * from participates_in_campaign join campaigns on name = campaign where member = %s", (member,))
            except psycopg2.Error as e:
                print("\nFailed to find members participating in a campaign\n")
            campaigns = cursor.fetchall()
            try:
                cursor.execute("select * from participates_in_activity join activities on id = activity where member = %s", (member,))
            except psycopg2.Error as e:
                print("\nFailed to find members participating in an activity\n")
            activities = cursor.fetchall()
            num_campaigns = mem_annotation[5]
            general_annotation = mem_annotation[4]
            if num_campaigns is None:
                num_campaigns = '0'
            if  general_annotation is None:
                general_annotation = ""
            print("\n---Member Info---")
            print("Name: "+mem_annotation[1]+"\nMember since: "+str(mem_annotation[3])+"\nCampaigns participated in: "+str(num_campaigns)+"\nGeneral member annotation: "+general_annotation+"\n")
            print("--Campaigns---")
            for instance in campaigns:
                annotation = instance[2]
                if annotation is None:
                    annotation = ""
                print("Campaign: "+instance[0]+"\nAnnotation: "+annotation+"\n")
            print("\n---Activities---")
            for instance in activities:
                annotation = instance[2]
                if annotation is None:
                    annotation = ""
                print("Activity ID: "+str(instance[0])+"\nDescription: "+instance[4]+"\nAnnotation: "+annotation+"\n")
            print("Would you like to add:\n[2] A general member annotation\n[3] A campaign annotation\n[4] An activity annotation\n[5] Go back")
            choice = input("Choice: ")
            if choice == '5':
                break

        member = input("\nPlease enter the member ID: ")
        mem_annotation = search_member(member)
        print("You have selected "+mem_annotation[1]+" is this correct (yes/no)")
        correct = input("Choice: ")
        if correct.lower() == 'no':
            break

        elif choice == '2':
            annotation = input("Please enter the annotation you would like to add: ")
            try:
                cursor.execute("UPDATE members set annotation = %s WHERE member_id = %s", (annotation, member))
            except psycopg2.Error as e:
                print("\nFailed to update annotation for member\n")
        elif choice == '3':
            campaign = input("Please enter the campaign name: ")
            annotation = input("Please enter the annotation you would like to add: ")
            try:
                cursor.execute("UPDATE participates_in_campaign set annotation = %s WHERE member = %s AND campaign = %s", (annotation, member, campaign))
            except psycopg2.Error as e:
                print("\nFailed to update annotation for member in campaign\n")
        elif choice == '4':
            activity = input("Please enter the Activity ID: ")
            annotation = input("Please enter the annotation you would like to add: ")
            try:
                cursor.execute("UPDATE participates_in_activity set annotation = %s WHERE member = %s AND activity = %s", (annotation, member, activity))
            except psycopg2.Error as e:
                print("\nFailed to update annotation for member in activity\n")
    dbconn.commit()

    cursor.close()
    dbconn.close()
def main():

    dbconn = psycopg2.connect(connection_string)
    cursor = dbconn.cursor()
    print("---Welcome to the GnG Management Service---")
    email_input = input("Please enter your email: ")
   
    pass_input = getpass.getpass('Password:')
    try:
        cursor.execute("select pass, member_id from members WHERE email = %s ", (email_input,))
    except psycopg2.Error as e:
        print("\nFailed to find a record of your credentials\n")
    hash_pass = cursor.fetchone()
    success = authenticate(hash_pass[0], pass_input)
    cursor.close()
    dbconn.close()
    if success is True:
        print("Successfully logged in")
        session_user = hash_pass[1]
    else:
        print("Login Failed: credentials do not match with records")
        sys.exit()
    
    
    while True:
        print("""What would you like to do?
[1] Create campaign
[2] Finances
[3] View Queries
[4] Annotations
[5] Quit""")
        if session_user == 1:
            print("[6] Set Password")

        choice = input("Choice: ")
        if choice == '1':
            print("""Would you like to:
[1] Create new campaign
[2] Go back""")
            choice = input("Choice: ")

            if choice == '1': 
                modify_campaign()

            if choice == '2':
                break;

        
        elif choice == '2':
            finances()
        
        elif choice == '3':
            view_queries()

        elif choice == '4':
            member_history()
            
        elif choice == '5':
            sys.exit()

        elif choice == '6' and session_user == 1:
            dbconn = psycopg2.connect(connection_string)
            cursor = dbconn.cursor()
            print("---Welcome to the GnG Password Change Service---")
            email_input = input("Please the account's email: ")
            pass_input = getpass.getpass('Please enter a new password:')
            hash_pass = set_pass(pass_input)
            try:
                cursor.execute("UPDATE members set pass = %s WHERE email = %s ", (hash_pass, email_input))
            except psycopg2.Error as e:
                print("\nFailed to update password\n")
            dbconn.commit()
            cursor.close()
            dbconn.close()


# Save most recent campaign names after it is entered and push it into other stages
# Put checkmark beside finished stages

if __name__ == "__main__": 
    main()
