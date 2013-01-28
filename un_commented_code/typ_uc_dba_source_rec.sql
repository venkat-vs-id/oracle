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
* ORACLE type used for the package which extract un-commented code from the dba_source
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

CREATE TYPE typ_uc_dba_source_rec AS OBJECT( 
                                      owner         VARCHAR2(50),
                                      name          VARCHAR2(50),
                                      type          VARCHAR2(50),
                                      line          NUMBER,
                                      text_org      VARCHAR2(4000),
                                      text_uc       VARCHAR2(4000),
                                      text_ucq      VARCHAR2(4000),
                                      text_c        VARCHAR2(4000),
                                      text_q        VARCHAR2(4000),                                      
                                      cursor_name   VARCHAR2(100),
                                      prc_name      VARCHAR2(100),
                                      fun_name      VARCHAR2(100),
                                      sub_prc_name  VARCHAR2(4000),
                                      sub_fun_name  VARCHAR2(4000),
                                      declare_area   VARCHAR2(1),
                                      log_text      VARCHAR2(4000),
                                      CONSTRUCTOR FUNCTION typ_uc_dba_source_rec RETURN self AS result,
                                      MEMBER PROCEDURE log_msg( p_msg VARCHAR2)  
                                      )
/
CREATE 
TYPE BODY typ_uc_dba_source_rec IS
  CONSTRUCTOR FUNCTION typ_uc_dba_source_rec
  RETURN self AS RESULT IS
  BEGIN
    owner        := NULL;
    NAME         := NULL;

TYPE :=
 NULL;
    line         := NULL;
    text_org         := NULL;
    text_uc      := NULL;
    text_ucq      := NULL;
    cursor_name  := NULL;
    prc_name     := NULL;
    fun_name     := NULL;
    sub_prc_name := NULL;
    sub_fun_name := NULL;
    log_text     := NULL;
    text_c       := null;
    text_q       := null;    
    declare_area := null;
    RETURN;
  END;
MEMBER PROCEDURE log_msg( p_msg VARCHAR2) IS
BEGIN
   LOG_TEXT := SUBSTR (LOG_TEXT || '~' || p_msg, 1, 4000);
   LOG_TEXT := LTRIM (LOG_TEXT, '~');
END log_msg;
end;
/
