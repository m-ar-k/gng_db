/*
 * Set up database and enter sample entries
 */


drop table members CASCADE;
drop table website CASCADE;
drop table activities CASCADE;
drop table campaigns CASCADE;
drop table real_estate CASCADE;

drop table rent_cost CASCADE;
drop table salary_cost CASCADE;
drop table activity_cost CASCADE;
drop table donor_donation CASCADE;
drop table activity_donation CASCADE;

drop table participates_in_campaign CASCADE;
drop table participates_in_activity CASCADE;
drop table website_changes CASCADE;
drop table in_campaign CASCADE;
drop table change_log CASCADE;

CREATE TABLE members (
   member_id int PRIMARY KEY,
   name varchar(25),
   email varchar(25) UNIQUE,
   join_date timestamp,
   annotation text,
   num_campaigns int, --for the volunteer isa hierarcy
   salary int, --for the employees isa hierarchy
   total_donations int,	--for the donors isa hierarchy 
   pass text
);

--Contains entities for all webpages on the website
CREATE TABLE website (
   webpage_url varchar(30) PRIMARY KEY, --maybe change this
   webpage_title varchar(30),
   date_added timestamp
);

--Contains entities for all the campaigns
CREATE TABLE campaigns (
   name varchar(20) PRIMARY KEY,
   goal varchar(30),
   started_on timestamp,
   date_completed timestamp,
   url varchar(30),
   completed boolean NOT NULL, --set to false by default
   foreign key (url) references website(webpage_url) on delete set null on update cascade

);

--Contains entities for all the activities which are part of campaigns
CREATE TABLE activities (
   id int PRIMARY KEY,
   description varchar(30),
   activity_date timestamp,
   campaign_name varchar(20),
   location varchar(20),
   url varchar(30),
   completed boolean NOT NULL, --set to false by default
   foreign key (campaign_name) references campaigns(name) on delete set null on update cascade,
   foreign key (url) references website(webpage_url) on delete set null on update cascade  
);

--Contains all the properties controlled by GnG such as their downtown office
CREATE TABLE real_estate (
   name varchar(20) PRIMARY KEY,
   address varchar(20),
   city varchar(20),
   province char(2),
   postalcode char(6),
   telephone char(10)
);

--Contains costs paid by organization associated with propterty rent
CREATE TABLE rent_cost (
   id int PRIMARY KEY,
   amount int,
   transaction_date timestamp,
   description varchar(30),
   rental_name varchar(20),

   foreign key (rental_name) references real_estate(name) on delete set null on update cascade
);

--Contains costs paid by organization associated with employee salaries
CREATE TABLE salary_cost (
   id int PRIMARY KEY,
   amount int,
   transaction_date timestamp,
   description varchar(30),
   employee_id int,

   foreign key (employee_id) references members(member_id) on delete set null on update cascade
);

--Contains costs paid by organization associated with running activites
CREATE TABLE activity_cost (
   id int PRIMARY KEY,
   amount int,
   transaction_date timestamp,
   description varchar(30),
   activity_id int,

   foreign key (activity_id) references activities(id) on delete set null on update cascade
);

--Contains donations recieved by GnG through activites
CREATE TABLE activity_donation (
   id int PRIMARY KEY,
   amount int,
   transaction_date timestamp,
   description varchar(25),
   activity_id int,

   foreign key (activity_id) references activities(id) on delete set null on update cascade
);

--Contains donations recieved by GnG through donors
CREATE TABLE donor_donation (
   id int PRIMARY KEY,
   amount int,
   transaction_date timestamp,
   description varchar(25),
   donor_id int,

   foreign key (donor_id) references members(member_id) on delete set null on update cascade
);

--Contains information on which campaign an activity is a part of
CREATE TABLE in_campaign (
   activity_id int PRIMARY KEY NOT NULL,
   campaign_name varchar(20)
);

--Contains relationship for members participating in campaigns
CREATE TABLE participates_in_campaign ( --many-many
   campaign varchar(20) REFERENCES campaigns(name) ON UPDATE CASCADE ON DELETE CASCADE,
   member int REFERENCES members(member_id) ON UPDATE CASCADE,
   annotation text,
   CONSTRAINT part_camp_key PRIMARY KEY (campaign, member)
);

--Contains relationship for members participating in activites
CREATE TABLE participates_in_activity ( --many-many
   activity int REFERENCES activities(id) ON UPDATE CASCADE ON DELETE CASCADE,
   member int REFERENCES members(member_id) ON UPDATE CASCADE,
   annotation text,
   CONSTRAINT part_act_key PRIMARY KEY (activity, member)
);

--Contains history of all changes made to pages of the website
CREATE TABLE website_changes ( --many-many
   url varchar(30) REFERENCES website(webpage_url) ON UPDATE CASCADE ON DELETE CASCADE,
   member int REFERENCES members(member_id) ON UPDATE CASCADE,
   created timestamp,
   CONSTRAINT website_key PRIMARY KEY(url, member)
);

CREATE TABLE change_log (
   id int PRIMARY KEY,
   member int,
   change_date timestamp,
   table_name text
);

--initial values to get databse started
insert into members values (1, 'simon', 'simon@gng.ca', CURRENT_TIMESTAMP, NULL, 1, 39000, NULL, '6ff2526f7def5c2d54d4b7b29f53f1a8215fa43d185cf34f5b348b5d56a73f43f43616b1dbb304d42072f122c0b926860b3846b34c8346d09d0d9a8338edb78034c6ae31d61317e5c36402837d29acbf7fb1a8b4f86ed1e49b602a0f541abb1e');
insert into website values ('gng.ca/initial_campaign', 'Initial Campaign Info', CURRENT_TIMESTAMP);
insert into website_changes values ('gng.ca/initial_campaign', 1, CURRENT_TIMESTAMP);
insert into campaigns values ('the ultimate', 'world domination', CURRENT_TIMESTAMP, NULL, 'gng.ca/initial_campaign', FALSE);
insert into activities values (1, 'hold posters', CURRENT_TIMESTAMP, 'the ultimate', 'Victoria', 'gng.ca/initial_campaign', FALSE);
insert into change_log values (1, 1, CURRENT_TIMESTAMP, 'campaigns');

insert into real_estate values ('downtown office', '456 Broad Street', 'Victoria', 'BC', 'V8Y3T8', '2505432342');
insert into rent_cost values (1, 2500, CURRENT_TIMESTAMP, 'office rent costs', 'downtown office');
insert into salary_cost values (1, 3250, CURRENT_TIMESTAMP, 'simon''s July paycheck', 1);
insert into activity_cost values (1, 25, CURRENT_TIMESTAMP, 'paper for posters', 1);

insert into members values (2, 'Andrew Anderson', 'aanderson@gng.ca', CURRENT_TIMESTAMP, NULL, NULL, NULL, 750);
insert into donor_donation values (1, 750, CURRENT_TIMESTAMP, 'Donation from A Anderson', 2);

insert into participates_in_campaign values ('the ultimate', 1);
insert into participates_in_activity values (1, 1);
insert into in_campaign values (1, 'the ultimate');

--members
   --volunteers >= 3
insert into members values (3, 'Benjamin Button', 'bbutton@gng.ca', CURRENT_TIMESTAMP, NULL, 5, NULL, NULL);
insert into members values (4, 'Charlie Chambers', 'cchambers@gng.ca', CURRENT_TIMESTAMP, NULL, 3, NULL, NULL);
insert into members values (5, 'Daniel Davis', 'ddavis@gng.ca', CURRENT_TIMESTAMP, NULL, 6, NULL, NULL);
insert into members values (6, 'Edward Edmonds', 'eedmonds@gng.ca', CURRENT_TIMESTAMP, NULL, 4, NULL, NULL);
insert into members values (7, 'Fred Fernwood', 'ffernwood@gng.ca', CURRENT_TIMESTAMP, NULL, 8, NULL, NULL);
insert into members values (8, 'Georgia Goldstein', 'ggoldstien@gng.ca', CURRENT_TIMESTAMP, NULL, 9, NULL, NULL);
insert into members values (9, 'Herbert Hedge', 'hhedge@gng.ca', CURRENT_TIMESTAMP, NULL, 5, NULL, NULL);
insert into members values (10, 'Bodaniel Beavis', 'bbeavis@gng.ca', CURRENT_TIMESTAMP, NULL, 6, NULL, NULL);
insert into members values (11, 'Ira Inglewood', 'iinglewood@gng.ca', CURRENT_TIMESTAMP, NULL, 7, NULL, NULL);
insert into members values (12, 'Jane Junipter', 'jjuniper@gng.ca', CURRENT_TIMESTAMP, NULL, 5, NULL, NULL);
insert into members values (13, 'Kelly Kooper', 'kkooper@gng.ca', CURRENT_TIMESTAMP, NULL, 10, NULL, NULL);

   --volunteers <= 2
insert into members values (14, 'Bill Buxton', 'bbuxton@gng.ca', CURRENT_TIMESTAMP, NULL, 1, NULL, NULL);
insert into members values (15, 'Carly Camper', 'ccamper@gng.ca', CURRENT_TIMESTAMP, NULL, 2, NULL, NULL);
insert into members values (16, 'Danielle Doris', 'ddoris@gng.ca', CURRENT_TIMESTAMP, NULL, 1, NULL, NULL);
insert into members values (17, 'Edna Emu', 'eemu@gng.ca', CURRENT_TIMESTAMP, NULL, 2, NULL, NULL);
insert into members values (18, 'Frank Ferdinand', 'fferdinand@gng.ca', NULL, CURRENT_TIMESTAMP, 1, NULL, NULL);

   --interested by not volunteered
insert into members values (19, 'Greg Gator', 'ggator@gng.ca', CURRENT_TIMESTAMP, NULL, 0, NULL, NULL);
insert into members values (20, 'Connor Camel', 'ccamel@gng.ca', CURRENT_TIMESTAMP, NULL, 0, NULL, NULL);
insert into members values (21, 'Helena Howard', 'hhoward@gng.ca', CURRENT_TIMESTAMP, NULL, 0, NULL, NULL);
insert into members values (22, 'Igor Iverson', 'iiverson@gng.ca', CURRENT_TIMESTAMP, NULL, 0, NULL, NULL);
insert into members values (23, 'Jack Jeffries', 'jjeffries@gng.ca', CURRENT_TIMESTAMP, NULL, 0, NULL, NULL);

   --employees (have a salary)
insert into members values (24, 'Kendrick Klooper', 'kklooper@gng.ca', CURRENT_TIMESTAMP, NULL, 12, 25000, NULL);
insert into members values (25, 'Lamar Landers', 'llanders@gng.ca', CURRENT_TIMESTAMP, NULL, 14, 27000, NULL);
insert into members values (26, 'Marco Montgomery', 'mmontgomery@gng.ca', CURRENT_TIMESTAMP, NULL, 11, 22500, NULL);
insert into members values (27, 'Nico Nordstrom', 'nnordstrom@gng.ca', CURRENT_TIMESTAMP, NULL, 9, 21500, NULL);
insert into members values (28, 'Oleg Oragami', 'ooragami@gng.ca', CURRENT_TIMESTAMP, NULL, 14, 28950, NULL);

   --donors (makes donations)
insert into members values (29, 'Peter Paggins', 'ppaggins@gng.ca', CURRENT_TIMESTAMP, NULL, NULL, NULL, 25000);
insert into members values (30, 'Quinn Quincy', 'qquincy@gng.ca', CURRENT_TIMESTAMP, NULL, NULL, NULL, 35000);
insert into members values (31, 'Ronaldo Roland', 'rroland@gng.ca', CURRENT_TIMESTAMP, NULL, NULL, NULL, 30000);


--Create web pages
insert into website values ('gng.ca/home', 'Home Page', CURRENT_TIMESTAMP);
insert into website values ('gng.ca/about', 'About GnG and values', CURRENT_TIMESTAMP);
insert into website values ('gng.ca/idle_no_more', 'Idle No More Events', CURRENT_TIMESTAMP);
insert into website values ('gng.ca/save_the_sea', 'Save the Sea Plan', CURRENT_TIMESTAMP);
insert into website values ('gng.ca/protect_our_forests', 'Forest Protest Schedule', CURRENT_TIMESTAMP);
insert into website values ('gng.ca/clean_air_project', 'Clean Air Canvasing', CURRENT_TIMESTAMP);

--Track website changes
insert into website_changes values ('gng.ca/home', 1, CURRENT_TIMESTAMP);
insert into website_changes values ('gng.ca/about', 24, CURRENT_TIMESTAMP);
insert into website_changes values ('gng.ca/idle_no_more', 26, CURRENT_TIMESTAMP);
insert into website_changes values ('gng.ca/save_the_sea', 26, CURRENT_TIMESTAMP);
insert into website_changes values ('gng.ca/protect_our_forests', 28, CURRENT_TIMESTAMP);
insert into website_changes values ('gng.ca/clean_air_project', 24, CURRENT_TIMESTAMP);

insert into campaigns values ('Idle No More', 'End idling on Van Isle', '03/03/2014 01:03:04', '04/03/2014 01:03:04', 'gng.ca/idle_no_more', TRUE);
insert into campaigns values ('Save the Sea', 'Stop Oil Tankers and Spills', '03/05/2016 02:10:04', '05/01/2016 02:10:04', 'gng.ca/save_the_sea', TRUE);
insert into campaigns values ('Protect Our Forests', 'End Old Growth Logging', '03/03/2018 05:03:01', NULL, 'gng.ca/save_the_sea', FALSE);
insert into campaigns values ('Clean Air Project', 'Close the Pulp Mill', '01/07/2019 07:05:04', NULL, 'gng.ca/clean_air_project', FALSE);

insert into activities values (2, 'hold posters', '03/05/2014 01:15:00', 'Idle No More', 'Victoria', 'gng.ca/idle_no_more', TRUE);
insert into activities values (3, 'door to door', '03/05/2014 01:15:00', 'Idle No More', 'Nanaimo', 'gng.ca/idle_no_more', TRUE);
insert into activities values (4, 'rally in town square', '03/07/2014 01:30:00', 'Idle No More', 'Duncan', 'gng.ca/idle_no_more', TRUE);

insert into activities values (5, 'kayak to tankers', '03/08/2016 02:30:04', 'Save the Sea', 'Sidney', 'gng.ca/save_the_sea', TRUE);
insert into activities values (6, 'rally near general store', '03/09/2016 05:10:04', 'Save the Sea', 'Tofino', 'gng.ca/save_the_sea', TRUE);
insert into activities values (7, 'protest at legislature', '03/12/2016 01:10:04', 'Save the Sea', 'Victoria', 'gng.ca/save_the_sea', TRUE);

insert into activities values (8, 'hold signs in woods', '03/04/2018 07:03:01', 'Protect Our Forests', 'Sooke', 'gng.ca/save_the_sea', TRUE);
insert into activities values (9, 'block logging trucks', '03/04/2018 12:03:01', 'Protect Our Forests', 'Comox', 'gng.ca/save_the_sea', TRUE);
insert into activities values (10, 'collect petitions', '03/10/2018 04:03:01', 'Protect Our Forests', 'Victoria', 'gng.ca/save_the_sea', TRUE);

insert into activities values (11, 'protest at Pulp Mill', '01/08/2019 08:05:04', 'Clean Air Project', 'Crofton', 'gng.ca/clean_air_project', TRUE);
insert into activities values (12, 'gather petitions', '03/08/2019 09:05:04', 'Clean Air Project', 'Ladysmith', 'gng.ca/clean_air_project', FALSE);
insert into activities values (13, 'protest at legislature', '05/08/2019 14:05:04', 'Clean Air Project', 'Victoria', 'gng.ca/clean_air_project', FALSE);

insert into salary_cost values (2, 3500, '01/01/2019 12:00:00', 'Kendrick''s December paycheck', 24);
insert into salary_cost values (3, 3500, '01/02/2019 12:00:00', 'Kendrick''s January paycheck', 24);
insert into salary_cost values (4, 3500, '01/03/2019 12:00:00', 'Kendrick''s February paycheck', 24);
insert into salary_cost values (5, 2950, '01/01/2019 12:00:00', 'Lamar''s December paycheck', 25);
insert into salary_cost values (6, 2950, '01/02/2019 12:00:00', 'Lamar''s January paycheck', 25);
insert into salary_cost values (7, 2950, '01/03/2019 12:00:00', 'Lamar''s February paycheck', 25);
insert into salary_cost values (8, 2450, '01/01/2019 12:00:00', 'Marco''s December paycheck', 26);
insert into salary_cost values (9, 2450, '01/02/2019 12:00:00', 'Marco''s January paycheck', 26);
insert into salary_cost values (10, 2450, '01/03/2019 12:00:00', 'Marco''s February paycheck', 26);
insert into salary_cost values (11, 2250, '01/01/2019 12:00:00', 'Nico''s December paycheck', 27);
insert into salary_cost values (12, 2250, '01/02/2019 12:00:00', 'Nico''s January paycheck', 27);
insert into salary_cost values (13, 2250, '01/03/2019 12:00:00', 'Nico''s February paycheck', 27);
insert into salary_cost values (14, 2150, '01/01/2019 12:00:00', 'Oleg''s December paycheck', 28);
insert into salary_cost values (15, 2150, '01/02/2019 12:00:00', 'Oleg''s January paycheck', 28);
insert into salary_cost values (16, 2150, '01/03/2019 12:00:00', 'Oleg''s February paycheck', 28);

insert into activity_cost values (2, 35, '03/05/2014 01:20:00', 'paper for posters', 2);
insert into activity_cost values (3, 25, '03/05/2014 01:20:00', 'printing pamphlets', 3);
insert into activity_cost values (4, 125, '03/07/2014 01:25:00', 'permit for rally', 4);

insert into activity_cost values (5, 60, '03/08/2016 02:30:04', 'transport to Sidney', 5);
insert into activity_cost values (6, 30, '03/09/2016 02:30:04', 'posters for rally', 6);
insert into activity_cost values (7, 135, '03/12/2016 02:30:04', 'permit for rally', 7);

insert into activity_cost values (8, 175, '03/04/2018 07:03:01', 'transport to Sooke', 8);
insert into activity_cost values (9, 475, '03/04/2018 07:03:01', 'transport to Comox', 9);
insert into activity_cost values (10, 75, '03/10/2018 07:03:01', 'food for volunteers', 10);

insert into activity_cost values (11, 150, '01/08/2019 08:05:04', 'transport to pulp mill', 11);
insert into activity_cost values (12, 75, '03/08/2019 09:05:04', 'printing petitions', 12);
insert into activity_cost values (13, 125, '05/08/2019 14:05:04', 'permit for rally', 13);

insert into donor_donation values (2, 1200, '03/07/2014 01:25:00', 'Donation from P Paggins', 29);
insert into donor_donation values (3, 750, '03/10/2018 07:03:01', 'Donation from P Paggins', 29);
insert into donor_donation values (4, 950, '03/09/2016 02:30:04', 'Donation from Q Quincy', 30);
insert into donor_donation values (5, 1350, '03/08/2019 09:05:04', 'Donation from Q Quincy', 30);
insert into donor_donation values (6, 2000, '03/10/2018 07:03:01', 'Donation from R Roland', 31);
insert into donor_donation values (7, 1500, '05/08/2019 14:05:04', 'Donation from R Roland', 31);

insert into activity_donation values (1, 150, '03/09/2016 05:10:04', 'Donation from Store', 6);
insert into activity_donation values (2, 75, '03/10/2018 04:03:01', 'Donation sign Petitions', 6);
insert into activity_donation values (3, 85, '05/08/2019 14:05:04', 'Donation legislat protest', 6);

insert into participates_in_campaign values ('Idle No More', 1, NULL);
insert into participates_in_campaign values ('Idle No More', 2, NULL);
insert into participates_in_campaign values ('Idle No More', 3, NULL);
insert into participates_in_campaign values ('Idle No More', 4, NULL);
insert into participates_in_campaign values ('Idle No More', 5, NULL);
insert into participates_in_campaign values ('Idle No More', 6, NULL);
insert into participates_in_campaign values ('Idle No More', 7, NULL);
insert into participates_in_campaign values ('Idle No More', 8, NULL);
insert into participates_in_campaign values ('Idle No More', 9, NULL);
insert into participates_in_campaign values ('Idle No More', 10, NULL);
insert into participates_in_campaign values ('Idle No More', 15, NULL);
insert into participates_in_campaign values ('Idle No More', 16, NULL);
insert into participates_in_campaign values ('Idle No More', 24, NULL);
insert into participates_in_campaign values ('Idle No More', 25, NULL);
insert into participates_in_campaign values ('Idle No More', 26, NULL);

insert into participates_in_activity values (2, 1, NULL);
insert into participates_in_activity values (2, 2, NULL);
insert into participates_in_activity values (2, 3, NULL);
insert into participates_in_activity values (2, 4, NULL);
insert into participates_in_activity values (2, 7, NULL);
insert into participates_in_activity values (2, 8, NULL);
insert into participates_in_activity values (2, 9, NULL);
insert into participates_in_activity values (3, 5, NULL);
insert into participates_in_activity values (3, 6, NULL);
insert into participates_in_activity values (3, 8, NULL);
insert into participates_in_activity values (3, 9, NULL);
insert into participates_in_activity values (3, 24, NULL);
insert into participates_in_activity values (3, 25, NULL);
insert into participates_in_activity values (3, 26, NULL);
insert into participates_in_activity values (4, 1, NULL);
insert into participates_in_activity values (4, 3, NULL);
insert into participates_in_activity values (4, 5, NULL);
insert into participates_in_activity values (4, 6, NULL);
insert into participates_in_activity values (4, 8, NULL);
insert into participates_in_activity values (4, 9, NULL);
insert into participates_in_activity values (4, 16, NULL);
insert into participates_in_activity values (4, 24, NULL);
insert into participates_in_activity values (4, 25, NULL);


insert into participates_in_campaign values ('Save the Sea', 1, NULL);
insert into participates_in_campaign values ('Save the Sea', 2, NULL);
insert into participates_in_campaign values ('Save the Sea', 3, NULL);
insert into participates_in_campaign values ('Save the Sea', 4, NULL);
insert into participates_in_campaign values ('Save the Sea', 5, NULL);
insert into participates_in_campaign values ('Save the Sea', 6, NULL);
insert into participates_in_campaign values ('Save the Sea', 7, NULL);
insert into participates_in_campaign values ('Save the Sea', 8, NULL);
insert into participates_in_campaign values ('Save the Sea', 12, NULL);
insert into participates_in_campaign values ('Save the Sea', 13, NULL);
insert into participates_in_campaign values ('Save the Sea', 17, NULL);
insert into participates_in_campaign values ('Save the Sea', 18, NULL);
insert into participates_in_campaign values ('Save the Sea', 27, NULL);
insert into participates_in_campaign values ('Save the Sea', 28, NULL);

insert into participates_in_activity values (5, 2, NULL);
insert into participates_in_activity values (5, 3, NULL);
insert into participates_in_activity values (5, 5, NULL);
insert into participates_in_activity values (5, 12, NULL);
insert into participates_in_activity values (5, 17, NULL);
insert into participates_in_activity values (5, 18, NULL);
insert into participates_in_activity values (5, 27, NULL);
insert into participates_in_activity values (5, 28, NULL);
insert into participates_in_activity values (6, 2, NULL);
insert into participates_in_activity values (6, 3, NULL);
insert into participates_in_activity values (6, 4, NULL);
insert into participates_in_activity values (6, 6, NULL);
insert into participates_in_activity values (6, 7, NULL);
insert into participates_in_activity values (6, 13, NULL);
insert into participates_in_activity values (6, 28, NULL);
insert into participates_in_activity values (7, 3, NULL);
insert into participates_in_activity values (7, 4, NULL);
insert into participates_in_activity values (7, 5, NULL);
insert into participates_in_activity values (7, 6, NULL);
insert into participates_in_activity values (7, 7, NULL);
insert into participates_in_activity values (7, 8, NULL);
insert into participates_in_activity values (7, 13, NULL);
insert into participates_in_activity values (7, 17, NULL);

insert into participates_in_campaign values ('Protect Our Forests', 3, NULL);
insert into participates_in_campaign values ('Protect Our Forests', 4, NULL);
insert into participates_in_campaign values ('Protect Our Forests', 5, NULL);
insert into participates_in_campaign values ('Protect Our Forests', 6, NULL);
insert into participates_in_campaign values ('Protect Our Forests', 7, NULL);
insert into participates_in_campaign values ('Protect Our Forests', 8, NULL);
insert into participates_in_campaign values ('Protect Our Forests', 9, NULL);
insert into participates_in_campaign values ('Protect Our Forests', 10, NULL);
insert into participates_in_campaign values ('Protect Our Forests', 11, NULL);
insert into participates_in_campaign values ('Protect Our Forests', 12, NULL);
insert into participates_in_campaign values ('Protect Our Forests', 13, NULL);
insert into participates_in_campaign values ('Protect Our Forests', 14, NULL);
insert into participates_in_campaign values ('Protect Our Forests', 15, NULL);
insert into participates_in_campaign values ('Protect Our Forests', 18, NULL);
insert into participates_in_campaign values ('Protect Our Forests', 25, NULL);
insert into participates_in_campaign values ('Protect Our Forests', 28, NULL);

insert into participates_in_activity values (8, 3, NULL);
insert into participates_in_activity values (8, 4, NULL);
insert into participates_in_activity values (8, 5, NULL);
insert into participates_in_activity values (8, 10, NULL);
insert into participates_in_activity values (8, 11, NULL);
insert into participates_in_activity values (8, 13, NULL);
insert into participates_in_activity values (8, 14, NULL);
insert into participates_in_activity values (8, 25, NULL);
insert into participates_in_activity values (9, 4, NULL);
insert into participates_in_activity values (9, 6, NULL);
insert into participates_in_activity values (9, 7, NULL);
insert into participates_in_activity values (9, 12, NULL);
insert into participates_in_activity values (9, 13, NULL);
insert into participates_in_activity values (9, 15, NULL);
insert into participates_in_activity values (9, 18, NULL);
insert into participates_in_activity values (9, 28, NULL);
insert into participates_in_activity values (10, 3, NULL);
insert into participates_in_activity values (10, 5, NULL);
insert into participates_in_activity values (10, 7, NULL);
insert into participates_in_activity values (10, 11, NULL);
insert into participates_in_activity values (10, 12, NULL);
insert into participates_in_activity values (10, 14, NULL);
insert into participates_in_activity values (10, 15, NULL);
insert into participates_in_activity values (10, 25, NULL);
insert into participates_in_activity values (10, 28, NULL);


insert into participates_in_campaign values ('Clean Air Project', 1, NULL);
insert into participates_in_campaign values ('Clean Air Project', 2, NULL);
insert into participates_in_campaign values ('Clean Air Project', 4, NULL);
insert into participates_in_campaign values ('Clean Air Project', 5, NULL);
insert into participates_in_campaign values ('Clean Air Project', 6, NULL);
insert into participates_in_campaign values ('Clean Air Project', 7, NULL);
insert into participates_in_campaign values ('Clean Air Project', 11, NULL);
insert into participates_in_campaign values ('Clean Air Project', 12, NULL);
insert into participates_in_campaign values ('Clean Air Project', 13, NULL);
insert into participates_in_campaign values ('Clean Air Project', 16, NULL);
insert into participates_in_campaign values ('Clean Air Project', 17, NULL);
insert into participates_in_campaign values ('Clean Air Project', 18, NULL);
insert into participates_in_campaign values ('Clean Air Project', 24, NULL);
insert into participates_in_campaign values ('Clean Air Project', 25, NULL);
insert into participates_in_campaign values ('Clean Air Project', 26, NULL);

insert into participates_in_activity values (11, 1, NULL);
insert into participates_in_activity values (11, 2, NULL);
insert into participates_in_activity values (11, 4, NULL);
insert into participates_in_activity values (11, 6, NULL);
insert into participates_in_activity values (11, 7, NULL);
insert into participates_in_activity values (11, 12, NULL);
insert into participates_in_activity values (11, 13, NULL);
insert into participates_in_activity values (11, 17, NULL);
insert into participates_in_activity values (11, 18, NULL);
insert into participates_in_activity values (11, 26, NULL);
insert into participates_in_activity values (12, 2, NULL);
insert into participates_in_activity values (12, 4, NULL);
insert into participates_in_activity values (12, 5, NULL);
insert into participates_in_activity values (12, 6, NULL);
insert into participates_in_activity values (12, 7, NULL);
insert into participates_in_activity values (12, 11, NULL);
insert into participates_in_activity values (12, 12, NULL);
insert into participates_in_activity values (12, 13, NULL);
insert into participates_in_activity values (12, 16, NULL);
insert into participates_in_activity values (12, 18, NULL);
insert into participates_in_activity values (12, 24, NULL);
insert into participates_in_activity values (12, 25, NULL);
insert into participates_in_activity values (13, 4, NULL);
insert into participates_in_activity values (13, 5, NULL);
insert into participates_in_activity values (13, 7, NULL);
insert into participates_in_activity values (13, 11, NULL);
insert into participates_in_activity values (13, 12, NULL);
insert into participates_in_activity values (13, 13, NULL);
insert into participates_in_activity values (13, 16, NULL);
insert into participates_in_activity values (13, 25, NULL);
insert into participates_in_activity values (13, 26, NULL);
