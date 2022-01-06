# migration_sendinblue
migration_identity


to run this script from local terminal and heroku configuration use the following command:
```
cat .path-to/migration.rb | heroku run console --app=levelup-identity --no-tty
```
This script will go for each list in your identity account and compare it with a list in your sendinblue Account in case the migration has faile in the process.
If the list does exist it will check ff the members of the list are in range diference of 30 people from the one in sendinblue. If this is true it will skip the list and check the next.
If this is not true (in case the migration stop in the half) it will delete that list in sendinblue and build it from scratch.

It this happen and/or the list does not exist in sendinblue, it will build it from scratch.

This is how it is created:
It create a list and then go to each member of the list in identity and check if the contact exist in sendingblue.
IF the member of the identity account is not a contact in Sendinblue it will create it migrating the following attributes:
```
   data=  {
		"email": "#{m.email}",
		"attributes": {
		"NOMBRE":"#{m.first_name == nil ? "": m.first_name }",
		"APELLIDOS":"#{m.last_name == nil ? "": m.last_name }",
		"CONTACT": "#{m.contact == nil ? "" : m.contact }",
		"SKYPE": "#{ (m.meta !=nil && m.meta.skype !=nil )? m.meta.skype : "" }",
		"TWITTER":"#{(m.meta !=nil && m.meta.twitter !=nil) ? m.meta.twitter : ""}",
		"Fecha de adicion": "#{m.created_at == nil ? "": m.created_at }",
		"Ultima modificacion": "#{m.updated_at == nil ? "": m.updated_at }",
		"JOINED_AT": "#{m.joined_at == nil ? "": m.joined_at }",
		"ACTION_HISTORY": "#{m.action_history == nil ? "": m.action_history }",
		"POINT_PERSON_ID": "#{m.point_person_id == nil ? "": m.point_person_id }",
		"ROLE_ID": "#{m.role_id == nil ? "": m.role_id }",
		"LAST_DONATED": "#{m.last_donated == nil ? "": m.last_donated }",
		"DONATIONS_COUNT": "#{m.donations_count == nil ? "": m.donations_count }",
		"AVERAGE_DONATION": "#{m.average_donation == nil ? "": m.average_donation }",
		"HIGHEST_DONATION": "#{m.highest_donation == nil ? "": m.highest_donation }",
		"MOSAIC_GROUP": "#{m.mosaic_group == nil ? "": m.mosaic_group }",
		"MOSAIC_CODE": "#{m.mosaic_code == nil ? "": m.mosaic_code }",
		"ENTRY_POINT": "#{m.entry_point == nil ? "": m.entry_point }",
		"LATITUDE": "#{m.latitude == nil ? "": m.latitude }",
		"LONGITUDE": "#{m.longitude == nil ? "": m.longitude }",
		"TITLE": "#{m.title == nil ? "": m.title }",
		"GENDER": "#{m.gender == nil ? "": m.gender }",
		"DONATION_PREFERENCE": "#{m.donation_preference == nil ? "": m.donation_preference }"
		}
	}
    
    ```
if the email is in bad format it will be added into a hash that will be display as a list at the end of the migration, and it will not be created in sendinblue.

Also, the migration create a "non list" where all the contact that are created are sended as well as to the proper list.

I hope this is usefull for everybody.

Catalina, head of tech in levelup :)
                
