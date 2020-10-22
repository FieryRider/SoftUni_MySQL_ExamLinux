# How to produce TSV output from MySQL Workbench or mysql cmd on Linux suitable for SoftUni's Judge
**SoftUni's Judge** expects the result of the queries to be in `TSV`(_Tab Separated Values_) format. When you copy _(CTRL-C)_ from the output table of the Linux version of **MySql Workbench** the contents is copies in CSV (_Comma Separated Values_) format. So there are 2 options to get `TSV` output suitable for **SoftUni's Judge**.
## Through MySql Workbench
1. Above the **result set table** there is a button ![Export button](https://i.gyazo.com/0cb3c89770dd8b833bc2ded460accf1b.png) for `Export/Import` which allows us to export the **result set table** as `TSV` file. Click it, then choose to export as `Tab separated` and save the **result set table** somewhere.
2. Open the file with a **text editor** and copy everything _(CTRL-A CTRL-C)_ 
3. Paste it into **SoftUni's Judge**.  
**IMPORTANT!!!** After pasting the result to **Judge** delete the first line of the result as it contains the **result set table** column names which cannot be normally copied from **MySql Workbench** and **SHOULD NOT BE INCLUDED IN THE SUBMISSION!**

## Through `mysql` cmdline / terminal
This is a little more complicated.
`MySqlMariadb` has the ability to export a result set to a file with custom column and line separaters. This is done by appending `INTO OUTFILE outfile.txt FIELDS TERMINATED BY '\t' OPTIONALLY ENCLOSED BY '\"' LINES TERMINATED BY '\n';` to the end of an `SELECT` query. There is a problem however. `MariaDB` does not have permission to write into any directory other that it's own dir _(most likely `/var/lib/mysql`)_ and it's own **tmp** dir _(/tmp/systemd-private-########################-mysql.service-######)_ (which require root access to read which is anoying).  
To fix that we need to edit it's **systemd service file**. We'll not going to edit the original file but instead we're going to override some of it's config with an `override.conf` file. To do this execute the following command `sudo systemctl edit mysqld.service` assuming the **MySql/MariaDB** service file is called `mysqld.service`. It'll open empty file with the default cmdline editor and we need to enter the following configuration
```systemd
[Service]
PrivateTmp=false
```
Then restart the `mysql.service` with `sudo systemctl restart mysql.service`.  
Now the **MariaDB** tmp dir will be `/tmp` which anyone has read/write access to and we can export the **result set table** to a `TSV` file in that dir

### Manual way
Run
```sh
mysql -u USER -p -e "USE \`database_name\`; THE_QUERY_THAT_IS_GIVEN_FOR_CHECKING_THE_TASK INTO OUTFILE '/tmp/output.tsv' FIELDS TERMINATED BY '\t' LINES TERMINATED BY '\n';"
```
(replacing `USER` AND `database_name` with ours and replacing `THE_QUERY_THAT_IS_GIVEN_FOR_CHECKING_THE_TASK` with the given query in the problem description)
For example if the check query is
```sql
SELECT COLUMN_KEY FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'instd'
AND COLUMN_NAME IN ('id','user_id','photo_id')
ORDER BY TABLE_NAME, COLUMN_KEY;
```

we need to run
```sh
mysql -u USER -p -e "USE \`instd\`; SELECT COLUMN_KEY FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = 'instd' AND COLUMN_NAME IN ('id','user_id','photo_id') ORDER BY TABLE_NAME, COLUMN_KEY INTO OUTFILE '/tmp/output.tsv' FIELDS TERMINATED BY '\t' LINES TERMINATED BY '\n';"
```
_Note that we removed the `;` at the end of the original check query because we have to append stuff to it_
### Through my script
* Edit the script and change `user` and `password` variables on lines `2` and `3` with your mysql login info for ex.
  ```sh
  #!/bin/bash
  #MySql login
  user='root'
  password='somePaS$'
  ...
  ```
* Make the script executable with `chmod ug+x mysql_check.sh`
* Run the script providing the **database name** as the first argument like so
  ```sh
  ./check.sh 'instd'
  ```
  ```
  Enter check query:
  SELECT COLUMN_KEY FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = 'instd' AND COLUMN_NAME IN ('id','user_id','photo_id') ORDER BY TABLE_NAME, COLUMN_KEY
  ```
  **(The check query has to be on a single line)**
* The result will be copied to your clipboard. Also there will be a result file in `/tmp/mysql/output.tsv` with the same result
