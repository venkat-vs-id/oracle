/*
*---------------------- Modification History ----------------------------------------
* 01|venkat.V.S.|12-dec-2012| created
*
*
*
*
*
*---------------------------
*     Description 
*----------------------------
* ORACLE collection type used for the package which extract un-commented code from the dba_source
* 
*
*---------------------------
*        Author
*----------------------------
* Venkat.V.S.
* http://venkat-echo.blogspot.com
* https://github.com/venkat-vs-id
* 
*
*------------------------------
*       Disclaimer
*------------------------------
*THESE PROGRAMS (CODE or SOFTWARE or DOCUMENTATION) SHARED BY ME ARE FURNISHED "AS IS". 
*THESE PROGRAMS ARE NOT THROUGHLY TESTED UNDER ALL CONDITIONS. I, THEREFORE CANNOT GAURANTEE OR IMPY RELIABILITY, SERVICEABILITY 
*OR THE FUNCTION OF THESE PROGRAMS.I MAKE NO WARRANTY, EXPRESS OR IMPLIED, AS TO THE USEFULNESS OF THESE PROGRAMS FOR ANY PURPOSE. 
*I ASSUME NO RESPONSIBILITY FOR THE USE OF THESE PROGRAMS; OR TO PROVIDE TECHNICAL SUPPORT TO USERS.
*
*----------------------------------------------------------------------------------------
*/
CREATE OR REPLACE
TYPE       typ_uc_dba_source_tab IS TABLE OF typ_uc_dba_source_rec
/
