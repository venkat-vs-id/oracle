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
CREATE OR REPLACE PACKAGE body PKG_HTML_eMAIL AS

  g_connection_id     NUMBER :=0;
  g_error_text        VARCHAR2(32000);
  
  --This is just a dummy, this is just required for utl_smtp
  g_rcpt    VARCHAR2(100) ;
  g_to      VARCHAR2(1000);
  g_cc      VARCHAR2(1000);
  g_subject VARCHAR2(100);

  g_css                 VARCHAR2(32000);
  g_body_title          VARCHAR2(1000);
  g_cell_alignment      VARCHAR2(1000);
  g_table_no_of_cols    NUMBER:=0;
  gt_html_body_empty    typ_html_body_text;
  gt_body_text          typ_html_body_text;
  gt_table_body_text    typ_html_body_text;

  C_H_CLASS     CONSTANT VARCHAR2(100):='H1';
  C_SH_CLASS    CONSTANT VARCHAR2(100):='H2';
  C_R_CLASS     CONSTANT VARCHAR2(100):='H3';

  exp_connection_error EXCEPTION;

 TYPE rec_tabledata IS RECORD( record_type  VARCHAR2(10), --H/SH/R
                               html_class   VARCHAR2(100),
                               record_data  VARCHAR2(32000),
                               no_of_cols   NUMBER
                            );
 TYPE tab_tabledata IS TABLE OF rec_tabledata INDEX BY BINARY_INTEGER;


 gt_tabledata       tab_tabledata;
 gt_tabledata_empty tab_tabledata;


PROCEDURE initVars IS
BEGIN
  g_error_text       := null;

  g_to               := null;
  g_cc               := null;
  g_subject          := null;
  g_css              := null;
  g_body_title       := null;
  g_table_no_of_cols := 0;
  gt_body_text       := gt_html_body_empty;
  gt_table_body_text := gt_html_body_empty;
  gt_tabledata       := gt_tabledata_empty;
END initVars;

FUNCTION getCSS
RETURN VARCHAR2 IS

  l_css VARCHAR2(32000);
BEGIN

   l_css :=
'
body{font-family:Aerial; font-size:12pt; margin:5px;}
h1{text-align:left; font-size:22px;}
h2{text-align:left; font-size:18px;}
.H1{background-color: #343992;color: #FFFFFF;
    font-weight : bold;
    padding : 3px 3px 3px; 
    text-align: center; 
    font-size: larger}
.H2{background-color: #ACBEF7;
    color: #343992;
    font-weight: bold;
    padding : 3px 3px 3px; 
    text-align: center;font-size: larger}
.H3{background-color: #DCE4FC;
    color : #000066;
    padding : 3px 3px 3px; 
    border-color:#98A1DB; 
    border-style:solid; 
    border-width:0px 1px 1px 0px; 
    font-size: smaller; font-weight:lighter}';

   g_css := l_css ||' '||g_css;

   RETURN g_css;

END getCSS;

FUNCTION getNext( pv_in_string     IN VARCHAR2,
                  pn_in_pos         IN NUMBER,
                  pv_in_delimiter  IN VARCHAR2 DEFAULT ',',
                  pv_in_endofstr   IN VARCHAR2 DEFAULT 'N' )
RETURN VARCHAR2 Is
 
 lv_result          VARCHAR2(32000);
 lv_temp_str        VARCHAR2(32000);BEGIN
  ---- add 1 , to the string, so that the last value will be returned.
  IF pn_in_pos  > 
     ( NVL( LENGTH(pv_in_string),0) - 
       LENGTH( NVL( REPLACE( pv_in_string,pv_in_delimiter), 0)) +1) THEN
 
     IF pv_in_endofstr = 'Y' THEN
        RETURN '$$END$$';
     ELSE
        RETURN NULL;
     END IF;
  ELSIF pn_in_pos <=0 THEN
    RETURN NULL;
  END IF;
  lv_temp_str := pv_in_string || pv_in_delimiter; 
  lv_result   := RTRIM( REGEXP_SUBSTR( lv_temp_str,'[^,]{0,},',1,pn_in_pos),',');
  RETURN lv_result;
END getNext;

PROCEDURE build_table_data IS

  idx               NUMBER:=0;
  col_idx           NUMBER :=0;

  l_record_class    VARCHAR2(100);
  l_data            VARCHAR2(32000);
  l_align_val       varchar2(10);
  l_align           varchar2(100);
BEGIN

  --- if gt_tabledata has records then it means the user wants us to build 
   -- the table, so add the <TABLE> tags
  IF gt_tabledata.COUNT > 0 THEN

     idx := gt_table_body_text.COUNT + 1;
     gt_table_body_text(idx):=
     '<table border="1" cellpadding="0" cellspacing="0">';
  END IF;

  FOR i in 1..gt_tabledata.COUNT
  LOOP

    l_record_class := null;
    IF gt_tabledata(i).record_type = 'H' THEN
       l_record_class := C_H_CLASS;
    ELSIF gt_tabledata(i).record_type = 'SH' THEN
      l_record_class := C_SH_CLASS;
    ELSIF gt_tabledata(i).record_type = 'R' THEN
      l_record_class := C_R_CLASS;
    END IF;

    idx := gt_table_body_text.COUNT + 1;
    gt_table_body_text(idx) := '<tr class="'
                               ||NVL(gt_tabledata(i).html_class,l_record_class)
                               ||'">';

    l_data  := NULL;
    col_idx := 0;
    LOOP
      col_idx := col_idx + 1;
      l_data := getNext( pv_in_string => gt_tabledata(i).record_data||'~[$$exit_now$$]',
                         pn_in_pos    => col_idx,
                         pv_in_delimiter => '~');
      IF l_data = '[$$exit_now$$]' THEN
         EXIT;
      END IF;

      ---- check and set the cell alignment
      l_align := NULL;
      l_align_val := UPPER( getNext( pv_in_string => g_cell_alignment,
                                                     pn_in_pos     => col_idx,
                                                     pv_in_delimiter => '~')
                          );

      IF l_align_val = 'R' THEN
         l_align := ' align="right" ';
      ELSIF l_align_val = 'L' THEN
         l_align := ' align="left" ';
      ELSIF l_align_val = 'c' THEN
         l_align := ' align="center" ';
      END IF;
      ---- if its is the LAST CELL's data the this cell_no is < total cols in the table
      -- use span
      IF (col_idx = gt_tabledata(i).no_of_cols) AND col_idx < g_table_no_of_cols THEN
        idx := gt_table_body_text.COUNT + 1;
        gt_table_body_text(idx) := '<td '||l_align||' colspan="'||
                                     to_char( (g_table_no_of_cols-col_idx)+1) 
                                     ||'">'||l_data||'</td>';
      ELSE
        idx := gt_table_body_text.COUNT + 1;
        gt_table_body_text(idx) := '<td '||l_align||'>'||l_data||'</td>';
      END IF;
    END LOOP;

    ---- End the TABLE tags on the LAST record
    IF i = gt_tabledata.COUNT THEN
      idx := gt_table_body_text.COUNT + 1;
       gt_table_body_text(idx) := '</table>';
    END IF;
  END LOOP;
END build_table_data;

--------------------------------------------------------------------------------
---------- HTML eMAIL methods
--------------------------------------------------------------------------------
FUNCTION getConnection
RETURN NUMBER IS
BEGIN
  initVars;
  g_connection_id := g_connection_id+1;

  RETURN g_connection_id;
END getConnection;

PROCEDURE setHeaders( p_conn_id         NUMBER,
                      p_to_emailIDs     VARCHAR2,
                      p_cc_emailIDs     VARCHAR2,
                      p_subject         VARCHAR2)IS
BEGIN

   IF g_connection_id != p_conn_id THEN
      RAISE exp_connection_error;
   END IF;

   g_to      := p_to_emailIDs;
   g_cc      := p_cc_emailIDs;
   g_subject := p_subject;

EXCEPTION
  WHEN exp_connection_error THEN
       g_error_text := 'Connection Error';
       RAISE;
END setHeaders;

PROCEDURE setBody( p_conn_id             NUMBER,
                   pt_html_body_text IN  typ_html_body_text) IS
BEGIN

   IF g_connection_id != p_conn_id THEN
      RAISE exp_connection_error;
   END IF;

   gt_body_text := pt_html_body_text;

EXCEPTION
  WHEN exp_connection_error THEN
       g_error_text := 'Connection Error';
       RAISE;
END setBody;

--------------------------------------------------------------------------------
----  HTML email Customization
--------------------------------------------------------------------------------
PROCEDURE setSender( p_conn_id      NUMBER,
                     p_from_emailID VARCHAR2)IS
BEGIN

   IF g_connection_id != p_conn_id THEN
      RAISE exp_connection_error;
   END IF;

   g_sender := p_from_emailID;

EXCEPTION
  WHEN exp_connection_error THEN
       g_error_text := 'Connection Error';
       RAISE;
END setSender;

PROCEDURE setCSS( p_conn_id IN NUMBER,
                  p_css     IN VARCHAR2) IS
BEGIN

   IF g_connection_id != p_conn_id THEN
      RAISE exp_connection_error;
   END IF;

   g_css := g_css ||' '||p_css;

EXCEPTION
  WHEN exp_connection_error THEN
       g_error_text := 'Connection Error';
       RAISE;
END setCSS;

PROCEDURE setBodyTitle( p_conn_id       NUMBER,
                        p_title         VARCHAR2) IS
BEGIN

   IF g_connection_id != p_conn_id THEN
      RAISE exp_connection_error;
   END IF;

   g_body_title := p_title;

EXCEPTION
  WHEN exp_connection_error THEN
       g_error_text := 'Connection Error';
       RAISE;
END setBodyTitle;

PROCEDURE setTableCellAlignment( p_conn_id             NUMBER,
                                  p_cell_alignment      VARCHAR2 
                                )IS
  l_idx NUMBER:=0;
BEGIN

 g_cell_alignment := p_cell_alignment;

END setTableCellAlignment;
PROCEDURE setTableBody( p_conn_id             NUMBER,
                        p_table_record        VARCHAR2,
                        p_record_type         VARCHAR2,
                        p_record_class        VARCHAR2 DEFAULT NULL) IS
  idx NUMBER;
  l_no_of_cols NUMBER;
BEGIN

   IF g_connection_id != p_conn_id THEN
      RAISE exp_connection_error;
   END IF;

   idx := gt_tabledata.COUNT+1;
   gt_tabledata( idx).record_type := p_record_type;
   gt_tabledata( idx).html_class  := p_record_class;
   gt_tabledata( idx).record_data := p_table_record;

   ---- identify the no of cols in each record
     -- need  +1 to count the last col
   l_no_of_cols := LENGTH( p_table_record) - 
                   LENGTH( REPLACE(p_table_record, '~')) + 1; 
                   
   gt_tabledata( idx).no_of_cols := l_no_of_cols;

   IF NVL( g_table_no_of_cols, 0) < l_no_of_cols THEN
      g_table_no_of_cols := l_no_of_cols;
   END IF;

EXCEPTION
  WHEN exp_connection_error THEN
       g_error_text := 'Connection Error';
       RAISE;
END setTableBody;

--------------------------------------------------------------------------------
----  Main method that sends the eMail
--------------------------------------------------------------------------------
FUNCTION sendEmail( p_conn_id        NUMBER)
RETURN NUMBER IS

  l_is_connection_open      BOOLEAN:=false;
  l_is_connection_data_open BOOLEAN:=false;
  l_idx                     NUMBER:=0;
  l_email                   VARCHAR2(100);
  c utl_smtp.connection;

  PROCEDURE set_header(name IN VARCHAR2, header IN VARCHAR2) AS
  BEGIN
    utl_smtp.write_data(c, name || ': ' || header || utl_tcp.CRLF);
  END set_header;

BEGIN

   IF g_connection_id != p_conn_id THEN
      RAISE exp_connection_error;
   END IF;

  ---- build the data and keep it ready
  --this build the table data if table_data records was populated
  PKG_HTML_eMAIL.build_table_data;  

  --- of the email-id separator is semi-colon or space then change that to comman
  g_to := REPLACE( REPLACE(LTRIM(RTRIM(g_to)), ';', ','), ' ', ',');
  g_cc := REPLACE( REPLACE(LTRIM(RTRIM(g_cc)), ';', ','), ' ', ',');
  --remove the comma at the end
  g_to := LTRIM( g_to, ',');

  c := utl_smtp.open_connection(g_mailhost); l_is_connection_open := TRUE;
  --utl_smtp.helo(c, 'say hello'); 
  -- Causes "ora-29279: smtp permanent error: 501 5.5.4 invalid domain name" 
  -- after lotus notes was removed from the email transport chain.
  utl_smtp.helo(c, g_mailhost);
  utl_smtp.mail(c, g_sender);

  ----you have to set all eMail-IDs in rcpt
  l_idx := 0;
  LOOP
    l_idx := l_idx + 1;
    l_email := getnext( pv_in_string    => g_to||','||g_cc||',[$$exit_now$$]',
                                        pn_in_pos        => l_idx,
                                        pv_in_delimiter => ',' );
    IF l_email = '[$$exit_now$$]' THEN
       EXIT;
    END IF;
    IF l_email IS NOT NULL THEN
       utl_smtp.rcpt(c, l_email);
    END IF;
  END LOOP;
  utl_smtp.open_data(c); l_is_connection_data_open := TRUE;

  ------------------------------------------------
  ---- Set the header
  ------------------------------------------------
  set_header('Content-Type', 'text/html');
  set_header('From',    g_sender);
  ---- This is the place where all the "to" eMAil-IDs should be given
  set_header('To',      g_to); 
  IF g_cc IS NOT NULL THEN
     set_header('cc',      g_cc);
  END IF;
  set_header('Subject', g_subject);

  ------------------------------------------------
  ---- Add the CSS
  ------------------------------------------------
  utl_smtp.write_data(c, utl_tcp.CRLF ||
  '<html>
       <head>
            <style type="text/css">'||getCSS||'
            </style>
       </head>
      <body>
  ');

  --------------------------------
  ---- HTML eMail Body
  --------------------------------
  IF g_body_title IS NOT NULL THEN
     utl_smtp.write_data(c, '<h2>'||g_body_title||'</h2>');
  ENd IF;

  ---- add the HTML TABLE data to the eMail body
  FOR hx IN 1..gt_table_body_text.COUNT
  LOOP
    utl_smtp.write_data(c, gt_table_body_text(hx));
  END LOOP;

  ---- Add the HTML body content
  FOR hx IN 1..gt_body_text.COUNT
  LOOP
    utl_smtp.write_data(c, gt_body_text(hx));
  END LOOP;

  --------------------------------
  ---- Close the HTML body
  --------------------------------
  utl_smtp.write_data(c,
   ' </body>
  </html>');

  utl_smtp.close_data(c);
  utl_smtp.quit(c);

  initVars;

  return 0;
EXCEPTION
  WHEN exp_connection_error THEN
       g_error_text := 'Connection Error';
       return 1;
  WHEN utl_smtp.transient_error OR utl_smtp.permanent_error THEN
       g_error_text := SQLERRM;
       BEGIN
          utl_smtp.quit(c);
       EXCEPTION
           WHEN utl_smtp.transient_error OR utl_smtp.permanent_error THEN
                g_error_text := SQLERRM;
                NULL; -- When the SMTP server is down or unavailable, we don't
                      -- have a connection to the server. The quit call will
                      -- raise an exception that we can ignore.
       END;
       return 1;
   WHEN OTHERS THEN
       g_error_text := DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ||'/'||SQLERRM;
       IF l_is_connection_open THEN
          utl_smtp.quit(c);
       END IF;
       return 1;
END sendEmail;

--------------------------------------------------------------------------------
----  Simple HTML email method
--------------------------------------------------------------------------------
FUNCTION sendSimpleEmail( p_to_emailIDs   VARCHAR2,
                          p_subject       VARCHAR2,
                          p_body          VARCHAR2)
RETURN NUMBER IS
  c      NUMBER;
  l_body typ_html_body_text;
BEGIN

  c := PKG_HTML_eMAIL.getConnection;
  PKG_HTML_eMAIL.setHeaders(p_conn_id=> c,
                       p_to_emailIDs => p_to_emailIDs,
                       p_cc_eMailIDs => null,
                       p_subject => p_subject);

  l_body(1) := p_body;
  PKG_HTML_eMAIL.setBody(p_conn_id=> c,
                        pt_html_body_text=>l_body);

  RETURN sendeMail(c);

END sendSimpleEmail;

FUNCTION getErrorText
RETURN VARCHAR2 IS
BEGIN

RETURN g_error_text;
END getErrorText;



END PKG_HTML_eMAIL;
/

