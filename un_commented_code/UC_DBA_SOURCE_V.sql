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
* ORACLE view used for the package which extract un-commented code from the dba_source
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
CREATE OR REPLACE FORCE VIEW UC_DBA_SOURCE_V AS
   SELECT dbo.owner,
          dbo.object_name,
          dbo.object_type,
          dbo.status,
          a.line,
          a.text_org text_org,
          a.text_uc text,
          a.text_ucq text_ucq,
          a.text_c text_c,
          a.text_q text_q,
          a.cursor_name,
          a.prc_name,
          a.fun_name,
          a.sub_prc_name,
          a.sub_fun_name,
          a.declare_area,
          a.log_text
     FROM dba_objects dbo,
          TABLE (
             CAST (uc_dba_source_fun (dbo.owner,
                                      dbo.object_name,
                                      dbo.object_type,
                                      dbo.status) AS typ_uc_dba_source_tab)) a
    WHERE object_type IN ('PROCEDURE', 'FUNCTION', 'PACKAGE', 'PACKAGE BODY');
