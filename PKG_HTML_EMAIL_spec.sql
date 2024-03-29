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
* It is an oracle package which can be used to send nicely formatted HTML emails from oracle DB using PLSQL.
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
CREATE OR REPLACE PACKAGE PKG_HTML_eMAIL AS


g_mailhost  VARCHAR2(100) := 'mailhost.domain.com';---REMEMBER To CHANGE HERE 
g_sender    VARCHAR2(100) := 'noreply@domain.com'; ---REMEMBER To CHANGE HERE 

--------------------------------------------------------------------------------
----  HTML email methods
--------------------------------------------------------------------------------
/****************************
 * Example-1 : Simple Email
 ****************************
DECLARE
  a NUMBER;

BEGIN
  a := PKG_HTML_eMAIL.sendSimpleEmail('test@domain.com', 
                                       'testing', 
             '<h1 id="test">Testing HTML body</h1>
              <table border="1" cellpadding="0" cellspacing="0">
                                            <tr class="H1">
                                               <td> R1 - C1 </td>
                                               <td> R1 - C2 </td>
                                               <td> R1 - C3 </td>
                                             </tr>
                                             <tr class="H2">
                                               <td> R2 - C1 </td>
                                               <td> R2 - C2 </td>
                                               <td> R2 - C3 </td>
                                             </tr>
                                         </table>');
  IF a != 0 THEN
     dbms_output.put_line('ERROR_TEXT:'||PKG_HTML_eMAIL.getErrorText);
     --then error
  END IF;
END;
*/

/******************************************
 * Example-2 : eMail with a table content
 ******************************************
DECLARE
  conn NUMBER;
  a NUMBER;

BEGIN
  conn := PKG_HTML_eMAIL.getConnection;
  PKG_HTML_eMAIL.setHeaders(p_conn_id=> conn,
                           p_to_emailIDs => 'test@domain.com,test2@domain.com',
                           p_cc_eMailIDs => null,
                           p_subject => 'testing customization');

  PKG_HTML_eMAIL.SetTableBody( conn, 'TABLE-Header', 'H', null);
  PKG_HTML_eMAIL.SetTableBody( conn, 'r1-c1~r1-c2~r1-c3', 'R', null);
  PKG_HTML_eMAIL.SetTableBody( conn, '~TOTAL~:10000', 'SH', null);
  PKG_HTML_eMAIL.SetTableBody( conn, 'r2-c1~r2-c2~r2-c3', '', null);
  PKG_HTML_eMAIL.SetTableBody( conn, 'TOTAL', 'SH', null);

  a := PKG_HTML_eMAIL.sendeMail(conn);

  IF a != 0 THEN
     dbms_output.put_line( 'ERROR_TEXT:'||PKG_HTML_eMAIL.getErrorText);
     -- then error
  END IF;
END;
*/

/********************************
 * Example-3 : Customized Email
 ********************************
DECLARE
  conn  NUMBER;
  a     NUMBER;
BEGIN

  conn := PKG_HTML_eMAIL.getConnection;
  PKG_HTML_eMAIL.setHeaders(p_conn_id=> conn,
                       p_to_emailIDs => 'test@domain.com,test2@domain.com',
                       p_cc_eMailIDs => null,
                       p_subject => 'testing customization');

  --<<<<<<<< customize the body title
  PKG_HTML_eMAIL.setBodyTitle( conn, '<h2> this is the BODY title </h2>');   
  --<<<<<<<< you can add your own CSS
  PKG_HTML_eMAIL.setCSS( conn, '.TblReportsHead4{background-color:red;}');   

  --<<<<<<<< customize the alignment of table cells 
  PKG_HTML_eMAIL.setTableCellAlignment(conn, 'L~R~C~');  

  --<<<<<<<< 'H' for header
  PKG_HTML_eMAIL.SetTableBody( conn, 'TABLE-Header', 'H', null);
  --<<<<<<<< 'R' for record   
  PKG_HTML_eMAIL.SetTableBody( conn, 'r1-c1~r1-c2~r1-c3', 'R', null); 
  --<<<<<<<< 'SH' for Sub-Header
  PKG_HTML_eMAIL.SetTableBody( conn, '~TOTAL~:10000', 'SH', null);    
  PKG_HTML_eMAIL.SetTableBody( conn, 'r2-c1~r2-c2~r2-c3', '', null);
  ----<<< use the CUSTOMIZED CSS here
  PKG_HTML_eMAIL.SetTableBody( conn, 'TOTAL', 'SH', 'TblReportsHead4');      

  a := PKG_HTML_eMAIL.sendeMail(conn);

  IF a != 0 THEN
     dbms_output.put_line( 'ERROR_TEXT:'||PKG_HTML_eMAIL.getErrorText);
     -- then error
  END IF;
END;
*/

TYPE typ_html_body_text IS TABLE OF varchar2(32767) INDEX BY BINARY_INTEGER;

FUNCTION getConnection
RETURN NUMBER;

PROCEDURE setHeaders( p_conn_id         NUMBER,
                      p_to_emailIDs     VARCHAR2,
                      p_cc_emailIDs     VARCHAR2,
                      p_subject         VARCHAR2);

PROCEDURE setBody( p_conn_id             NUMBER,
                   pt_html_body_text IN  typ_html_body_text);

--------------------------------------------------------------------------------
----  HTML email Customization
--------------------------------------------------------------------------------
PROCEDURE setSender( p_conn_id      NUMBER,
                     p_from_emailID VARCHAR2);

PROCEDURE setCSS( p_conn_id IN NUMBER,
                  p_css     IN VARCHAR2);

PROCEDURE setBodyTitle( p_conn_id       NUMBER,
                        p_title         VARCHAR2);

PROCEDURE setTableCellAlignment
( p_conn_id             NUMBER,
  p_cell_alignment      VARCHAR2-- tild(~) separated e.g 'L~R~L~L' for a 4 column table 
);

---- this method automatically calculates the no of cols required. It takes the maximum and spans the rest
PROCEDURE setTableBody
( p_conn_id      NUMBER,
  p_table_record VARCHAR2, --- separate column values using tild(~)
  p_record_type  VARCHAR2,--H(header)/SH(sub  header)/R(Record)/null
  p_record_class VARCHAR2 DEFAULT NULL);

--------------------------------------------------------------------------------
--Main method that sends the eMail using the data assigned using the above methods
--------------------------------------------------------------------------------
FUNCTION sendEmail( p_conn_id  NUMBER)
RETURN NUMBER;

--------------------------------------------------------------------------------
----  Simple HTML email method
--------------------------------------------------------------------------------
FUNCTION sendSimpleEmail( p_to_emailIDs   VARCHAR2,
                          p_subject       VARCHAR2,
                          p_body          VARCHAR2)
RETURN NUMBER;

--------------------------------------------------------------------------------
----  find the ERROR TEXT
--------------------------------------------------------------------------------
FUNCTION getErrorText
RETURN VARCHAR2;

END PKG_HTML_eMAIL;
/

