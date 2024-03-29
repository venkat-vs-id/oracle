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
* ORACLE function used for the package which extract un-commented code from the dba_source
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
CREATE OR REPLACE function uc_dba_source_fun( p_obj_owner  VARCHAR2,
                                              p_obj_name   VARCHAR2,
                                              p_obj_type   VARCHAR2,
                                              p_obj_status VARCHAR2     
                                            ) 
RETURN typ_uc_dba_source_tab IS

 l_lines_tab        typ_uc_dba_source_tab:= typ_uc_dba_source_tab();
 l_hy_cnt           NUMBER;    
 l_wrapped_header   VARCHAR2(32000);
 l_wrapped_defn_str VARCHAR2(500):= '^(\s)*(PROCEDURE |FUNCTION |PACKAGE |PACKAGE BODY )(\s)*(.)*?( wrapped )';

FUNCTION replace_chr2Space( p_text IN VARCHAR2)
RETURN VARCHAR2 IS
  l_txt VARCHAR2(32000);
BEGIN
  
  l_txt := REGEXP_REPLACE( p_text, '('||CHR(10)||'|'||CHR(13)||'|'||CHR(9)||')', ' ', 1, 0, 'i');
  
  RETURN l_txt;
END replace_chr2Space;
 
FUNCTION get_cur_prc_fun_name( p_line          NUMBER,
                                p_out_fwd_dec   OUT VARCHAR2, -- Y/N
                                p_cur_prc_fun   OUT VARCHAR2 -- CUR/PRC/FUN
                              )
RETURN VARCHAR2 IS   ---- return prc or fun name
    
    l_new_text         VARCHAR2(5000);

    l_defn_text        VARCHAR2(32000);
    l_defn_type        VARCHAR2(100);   
    l_defn_fwd_dec     VARCHAR2(1); -- Y / N 
    l_defn_name        VARCHAR2(50);    
    l_regexp_defn_str  VARCHAR2(500):= '^(\s)*(CURSOR |PROCEDURE |FUNCTION )([[:alnum:]]+([[_]]*[[:alnum:]]*)*)(\s)*(\(| )?(.)*?( IS |\)IS|;)(\s)*(.)*$';
    l_cnt              NUMBER:=0;

 BEGIN
   p_cur_prc_fun := NULL;
   p_out_fwd_dec := NULL; 

   FOR lx IN p_line..l_lines_tab.COUNT
   LOOP

      l_new_text := l_lines_tab(lx).TEXT_ucq;

      l_new_text := REPLACE( l_new_text, CHR(10), ' ');
      l_new_text := REPLACE( l_new_text, CHR(13), ' ');
      l_new_text := REPLACE( l_new_text, CHR(9), ' ');
      l_new_text := REGEXP_REPLACE( l_new_text, '( ){2,}',' ');

      IF lx = p_line THEN --- on the first line

         l_defn_type := REGEXP_REPLACE( l_new_text, '^(\s)*(PROCEDURE |FUNCTION |CURSOR )(.)*?$', '\2', 1, 0, 'i');

         l_defn_type := LTRIM( RTRIM( UPPER( l_defn_type)));
         IF l_defn_type = 'PROCEDURE' THEN
            l_defn_type := 'PRC';
         ELSIF l_defn_type = 'FUNCTION' THEN
            l_defn_type := 'FUN';
         ELSIF l_defn_type = 'CURSOR' THEN
            l_defn_type := 'CUR';
         ELSE
            ---- this is not a cursor or procedure or function line
            RETURN null;
         END IF;
      END IF;

      l_defn_text := l_defn_text||l_new_text;
      ---- cheking for cursor/procedure/function definition  
      IF REGEXP_INSTR( l_defn_text, l_regexp_defn_str, 1, 1, 0, 'i') != 0 THEN

         l_defn_name := REGEXP_REPLACE( l_defn_text, l_regexp_defn_str, '\3', 1, 0, 'i');
         IF LTRIM( RTRIM( UPPER( REGEXP_REPLACE( l_defn_text, l_regexp_defn_str, '\8', 1, 0, 'i')))) IN( 'IS', ')IS') THEN
            l_defn_fwd_dec := 'N';
         ELSIF LTRIM( RTRIM( UPPER( REGEXP_REPLACE( l_defn_text, l_regexp_defn_str, '\8', 1, 0, 'i')))) = ';' THEN
            l_defn_fwd_dec := 'Y';
         END IF;
               
         EXIT;  
      END IF;
      l_cnt := l_cnt +1;
   END LOOP;
   
   p_cur_prc_fun := l_defn_type;
   p_out_fwd_dec := l_defn_fwd_dec; 
   
   RETURN l_defn_name;
 END get_cur_prc_fun_name;
------------------------------------------------------------------------------- 
BEGIN
 ---------------------------------------------
 --- Get the SOURCE code   
 ---------------------------------------------
 ----- Collect all the source lines for the passed object. these are the original lines
 SELECT *
        BULK COLLECT INTO l_lines_tab
   FROM ( SELECT typ_uc_dba_source_rec( owner, name, type, line, text, 
                                           --DECODE( p_obj_status, 'VALID', NULL, 'The object has to be VALID to do UC processing'),
                                           null, 
                                           null, null, null, null, null, null, null, null, null, null
                                         )
            FROM dba_source ds
           WHERE owner = p_obj_owner
             AND name  = p_obj_name
             AND type  = p_obj_type
             --and line  = DECODE( p_obj_status, 'VALID', ds.line, 1)  
             AND line  = ds.line
        ORDER BY line
       );

 ---------------------------------------------
 --- check if the code is wrapped  
 ---------------------------------------------
 FOR lx IN 1..3
 LOOP
    l_wrapped_header := l_wrapped_header||' '||REPLACE( REPLACE( l_lines_tab(lx).text_org, CHR(10), ' '), CHR(13), ' ');
    
    IF REGEXP_INSTR( l_wrapped_header, l_wrapped_defn_str, 1, 1, 0, 'i') > 0 THEN
    
       -----VVVVVVVVVVVVVVVVVVVVVVVVVVVVV
       ----->>> There is a RETURN HERE  <<<<<<<<
       -----^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
       RETURN l_lines_tab;            
    END IF;
 END LOOP;

 ---------------------------------------------
 --- GET UnCommented code   
 ---------------------------------------------
 DECLARE 
    C_END_CHARS  CONSTANT VARCHAR2(12):= '[<~/*''*/~>]';
    C_OPEN_Q     CONSTANT VARCHAR2(12):= '[<~/*''*/~>]';
    C_OPEN_NA    CONSTANT VARCHAR2(10):= '[<~~>]';
    C_OPEN_C     CONSTANT VARCHAR2(10):= '~>]';
 
    l_text                  VARCHAR2(32000);
    l_comment_quote_active  VARCHAR2(2);
    l_start                 NUMBER;
    l_dummy                 NUMBER;
    l_quote_pos             NUMBER;
    l_comment_pos           NUMBER;    
 BEGIN   
    FOR lx IN 1..l_lines_tab.COUNT
    LOOP
        l_text := REPLACE( REPLACE( l_lines_tab(lx).text_org, CHR(10)), CHR(13));
        
        ---- if there is a comment or a quote active from previous line, then just add that in the front of this line, 
          -- so that we can apply the logic respectively.
        IF  l_comment_quote_active = '/*' THEN

            l_text  := '/*'||l_text;
        ELSIF l_comment_quote_active = 'Q' THEN

            l_text  := ''''||l_text;
        END IF;
        
        ---- the end chars is attached so that it is easy to find if there is a open quotes or open comment
        l_text  := l_text || C_END_CHARS; 
        
        ---- get the un-commented CODE, in the CURRENt LINE
        l_start := 1;
        l_dummy := 1;
        loop
          -- Check the starting pos of a QUOTE or a comment. If they dont exists then it return the end of STRING.
          l_quote_pos   := REGEXP_INSTR( l_text, CHR(39)||'|$', l_start);
          l_comment_pos := REGEXP_INSTR( l_text, '--|/\*|$', l_start);

          -- Check whose POSITION is less, which means who comes first and we have to handle for that.
          if l_comment_pos < l_quote_pos then
             
             ---- Gets the commented text 
             l_lines_tab(lx).text_c := l_lines_tab(lx).text_c||
                                       REGEXP_REPLACE( l_text, 
                                                       '^(.*?)((--){1,1}(.*?)|(/\*){1,1}(.*?)(\*/)(.*?))$', '\4\6', 1, 1);

             l_text  := REGEXP_REPLACE( l_text, '(--){1,1}.*?$|(/\*){1,1}.*?(\*/)', '', l_start, 1);
          elsif l_quote_pos < l_comment_pos then

             l_start := REGEXP_INSTR( l_text, '(''){1,1}([^'']*)',l_quote_pos,1,1)+1;
          end if;

          if l_start        > LENGTH( l_text) OR
             l_comment_pos  > LENGTH( l_text) OR
             l_comment_pos  = l_quote_pos     OR
             l_text IS NULL THEN

             EXIT;
          end if;

          ---- to be safe.. there cant be more than 50 comments or quotes in one LINE.. 
          l_dummy := l_dummy + 1;
          if l_dummy = 50 then

             EXIT;
          end if;
        end loop;

        ---- This is to get the uncommented + un-quoted text, and replace the text inside the quotes with [Q]
        l_lines_tab(lx).text_ucq := REGEXP_REPLACe( l_text, '(''(.)*?'')','[Q]',1);
        
        ---- get the text within the quotes.. 
          -- the addition of ||'''''' to the end it a trick logic to avoid the unwanted chars after the last quote text ( if any)
        l_lines_tab(lx).text_q := REGEXP_REPLACe( l_text||'''''', '.*?(''(.)*?'').*?', '\1~', 1);
                        
        ---- Now remove the QUOTE that was added to the front of the line at the begining. 
          --we need not do that for comments as as that would have been removed by now..
        IF l_comment_quote_active = 'Q' THEN
           l_text  := SUBSTR( l_text, 2);
        END IF;
        
        ---- To check if there is a open comment or open Quote at the end of this line 
          -- and remove the remaining chars from "C_END_CHARS" which was added to the end of the line, in the begining of the logic 
          -- NOTE: the order of the IF statements are important.
        IF SUBSTR( l_text, LENGTH(C_OPEN_NA)*-1) = C_OPEN_NA THEN

           l_comment_quote_active := NULL;
           l_text := SUBSTR( l_text, 1, LENGTH(l_text) - LENGTH(C_OPEN_NA));
        ELSIF SUBSTR( l_text, LENGTH(C_OPEN_Q)*-1) = C_OPEN_Q THEN

           l_comment_quote_active := 'Q';
           l_text := SUBSTR( l_text, 1, LENGTH(l_text) - LENGTH(C_OPEN_Q));
        ELSIF SUBSTR( l_text, LENGTH(C_OPEN_C)*-1) = C_OPEN_C THEN

           l_comment_quote_active := '/*';
           l_text := SUBSTR( l_text, 1, LENGTH(l_text) - LENGTH(C_OPEN_C));
        ELSE

           l_comment_quote_active := NULL;
        END IF;

        l_text := l_text ||CHR(10);

        ---- the UC line is assigned here
        l_lines_tab(lx).text_uc  := l_text;
        
        ---- Clean the quote TEXT extract: just replace for un-commented un-quoted text
        l_lines_tab(lx).text_ucq := REPLACE( l_lines_tab(lx).text_ucq, '[Q]*/~>]', '[Q]');
        l_lines_tab(lx).text_ucq := REPLACE( l_lines_tab(lx).text_ucq, '[<~~>]', '');
        l_lines_tab(lx).text_ucq := REPLACE( l_lines_tab(lx).text_ucq, '~>]', '');
        l_lines_tab(lx).text_ucq := REPLACE( l_lines_tab(lx).text_ucq, '[Q]', '');
        l_lines_tab(lx).text_ucq := l_lines_tab(lx).text_ucq || CHR(10);
        
        ---- Clean the commented text extract
        l_lines_tab(lx).text_c := REPLACE(l_lines_tab(lx).text_c, '''', '');
        l_lines_tab(lx).text_c := REGEXP_REPLACE(l_lines_tab(lx).text_c, '^(.*?)((\[<~/\*\*/~>\])|(\[<~/\*)|(\[<~/)|(/~>\])|(\*/~>\]))(\s)*$', '\1');
        l_lines_tab(lx).text_c := l_lines_tab(lx).text_c || chr(10);
        ---- to preserve the space within the comments
        --l_lines_tab(lx).text_c := TRIM(l_lines_tab(lx).text_c);
    END LOOP;
 END;
   
 ---- at this point we have the complete un-commented code in l_lines_tab
   -- now loop again to get the other details like prc/fun/cursor/forward dec names
 DECLARE
    lg_cursor_active        VARCHAR2(1);
    lg_cursor_name          VARCHAR2(50);

    lg_prc_fun_active       VARCHAR2(1);
    lg_prc_fun_name         VARCHAR2(50);
    lg_fwd_decl_flag        VARCHAR2(10);

    lg_cur_fun_prc_flag     VARCHAR2(10);     

    lg_sub_prc_fun_active   VARCHAR2(1);
    lg_sub_prc_fun_name     VARCHAR2(4000);
    lg_sub_fwd_decl_flag    VARCHAR2(10);

    lg_sub_fun_prc_flag     VARCHAR2(10);     
        
    lg_begin_cnt            NUMBER:=0;
    lg_sub_sub_function     NUMBER:=0;
    
    l_declare_active          VARCHAR2(1);

 BEGIN  
    FOR lx IN 1..l_lines_tab.COUNT
    LOOP
        ----------------------------
        ---- cursor
        ----------------------------
        DECLARE
           l_new_text            VARCHAR2(5000) := l_lines_tab(lx).text_ucq;
           l_dummy_text          VARCHAR2(30);
        BEGIN
           l_new_text := REPLACE( l_new_text, CHR(9),' ');
           l_new_text := REPLACE( l_new_text, CHR(10),' ');
           l_new_text := REGEXP_REPLACE( l_new_text, '( ){2,}',' ');

           IF lg_cursor_active is null THEN
              lg_cursor_name  := null;
           END IF;

           ---- then search for cursor
           IF lg_cursor_active IS NULL THEN
              IF REGEXP_INSTR( l_new_text, '(^| )CURSOR ', 1, 1, 0, 'i') > 0 THEN

                 lg_cursor_active := 'Y';
                 lg_cursor_name   := get_cur_prc_fun_name( lx, l_dummy_text, l_dummy_text);
              END IF;
           END IF;

           IF lg_cursor_active IS NOT NULL THEN
              IF INSTR( l_new_text, ';') > 0 THEN
                 lg_cursor_active := null;  
              END IF;
           END IF;
              
           ---- the CURSOR NAME is assigned here
           l_lines_tab(lx).cursor_name := lg_cursor_name;  
        END;

        ----------------------------
        ---- procedure / functions
        ----------------------------        
        DECLARE
          l_new_text                VARCHAR2(5000):= l_lines_tab(lx).text_ucq;
          l_prc_fun_regexp_str      VARCHAR2(500):= '^(\s)*(PROCEDURE |FUNCTION )';
              
        BEGIN
               l_new_text := REPLACE( l_new_text, CHR(10), ' ');
               l_new_text := REPLACE( l_new_text, CHR(13), ' ');
               l_new_text := REPLACE( l_new_text, CHR(9), ' ');
               l_new_text := REGEXP_REPLACE( l_new_text, '( ){2,}',' ');

               ---- if prc/fun is not active then search for the prc/fun strings
               IF lg_prc_fun_active IS NULL THEN

                  ---- Initialize the variables
                  lg_prc_fun_name     := null;
                  lg_fwd_decl_flag    := null;
                  lg_cur_fun_prc_flag := null;
                  lg_begin_cnt        := 0;

                  ---- if the line has FUNCTION / PROCEDURE string
                  IF REGEXP_INSTR( l_new_text, l_prc_fun_regexp_str, 1, 1, 0, 'i') != 0 THEN
                    
                     ---- get the fun or prc name here... this also get the info on if it is a FWD dec or not
                     lg_prc_fun_name   := get_cur_prc_fun_name( lx, lg_fwd_decl_flag, lg_cur_fun_prc_flag);
                     lg_prc_fun_active := 'Y';
                  END IF;

                  ---- to g_begin_cnt, add 1 to BEGIN and -1 for END.. this is to cater for begin in the same line of procedure/fun  
                  --IF REGEXP_INSTR( l_new_text, '^(\s)*(PROCEDURE |FUNCTION )(.)*?( IS)(\s)*BEGIN ', 1, 1, 0, 'i') != 0 THEN
                  IF REGEXP_INSTR( l_new_text, '^((PROCEDURE |FUNCTION ){0,1}(.)*?( IS)){0,1}(\s)*BEGIN ', 1, 1, 0, 'i') != 0 THEN
                     lg_begin_cnt := lg_begin_cnt + 1;
                  END IF;
                  
               ELSE 

                  IF lg_sub_prc_fun_active IS NULL THEN
                     
                     lg_sub_prc_fun_name    := null;
                     lg_sub_fun_prc_flag    := null;
                         
                     ---- search for SUB procedure or function
                     IF REGEXP_INSTR( l_new_text, l_prc_fun_regexp_str, 1, 1, 0, 'i') != 0 THEN

                        lg_sub_prc_fun_name   := get_cur_prc_fun_name( lx, lg_sub_fwd_decl_flag, lg_sub_fun_prc_flag);
                        lg_sub_prc_fun_active := 'Y';
                     END IF;
                  ELSE 
                    --// This means there is a SUB-FUNCTION within another SUB-FUNCTIION

                     IF REGEXP_INSTR( l_new_text, l_prc_fun_regexp_str, 1, 1, 0, 'i') != 0 THEN

                        lg_sub_prc_fun_name   := lg_sub_prc_fun_name||','||
                                                 get_cur_prc_fun_name( lx, lg_sub_fwd_decl_flag, lg_sub_fun_prc_flag);
                        lg_sub_prc_fun_active := 'Y';
                     END IF;
                  END IF;
                 
                  ---- to g_begin_cnt, add 1 to BEGIN and -1 for END.. so when it is 0 then it is one complete "PLSQL block" 
                  IF REGEXP_INSTR( l_new_text, '^((PROCEDURE |FUNCTION ){0,1}(.)*?( IS)){0,1}(\s)*BEGIN ', 1, 1, 0, 'i') != 0 THEN
                     lg_begin_cnt := lg_begin_cnt + 1;
                  END IF;
                  
                  --l_lines_tab(lx).log_msg( lg_cur_fun_prc_flag || ' / '|| lg_prc_fun_name||' / '||lg_begin_cnt||'/=>'||lg_sub_prc_fun_active||'/'||REGEXP_INSTR( l_new_text, '^(\s)*(END)(\s)*([[:alnum:]]+([[_]]*[[:alnum:]]*)*){0,1}(\s)*(;)', 1, 1, 0, 'i'));
                  
                  ---- different ways in which a PRC / FUN / PLSQL block( begin-end) ends
                  IF (     REGEXP_INSTR( l_new_text, '^(\s)*(END)(\s)*([[:alnum:]]+([[_]]*[[:alnum:]]*)*){0,1}(\s)*(;)', 1, 1, 0, 'i') != 0   
                       AND REGEXP_INSTR( l_new_text, '(\s)*(END)(\s)+(LOOP)(\s)*(;)' , 1, 1, 0, 'i') = 0  
                       AND REGEXP_INSTR( l_new_text, '(\s)*(END)(\s)+(IF)(\s)*(;)' , 1, 1, 0, 'i') = 0
                       AND REGEXP_INSTR( l_new_text, '(\s)*(END)(\s)+(CASE)(\s)*(;)' , 1, 1, 0, 'i') = 0  
                     ) THEN

                     ---- if begin count is = 1 and if something ends then it is the end of parent fun/prc
                       -- ELSE it might be a nested block. so it might be a end of just a inner PLSQL block
                     IF lg_begin_cnt = 1  THEN
                        ---- if the begin cnt =1 and also the sub is active then it is end of sub
                          -- ELSE it is the end of parent prc/fun
                        IF NVL( lg_sub_prc_fun_active, 'N') = 'Y' THEN
                           
                           IF INSTR( lg_sub_prc_fun_name, ',') > 0 THEN
                              
                              lg_sub_prc_fun_name := SUBSTR( lg_sub_prc_fun_name, 1, INSTR(lg_sub_prc_fun_name, ',', -1)-1);
                              lg_begin_cnt := lg_begin_cnt - 1;    
                           ELSE 
                              lg_begin_cnt := lg_begin_cnt - 1;
                              lg_sub_prc_fun_active := null;
                           END IF;   
                        ELSE
                           
                           lg_prc_fun_active := null;
                           lg_begin_cnt      := 0;
                        END IF;
                     ELSE
                        lg_begin_cnt := lg_begin_cnt - 1;
                     END IF;
                     --l_lines_tab(lx).log_msg( ' inside chk '||'/'||lg_begin_cnt||'>lg_sub_prc_fun_active>>'||lg_sub_prc_fun_active);
                  END IF;
               END IF;
               
               --l_lines_tab(lx).log_msg( ' inside chk '||'/'||lg_begin_cnt||'>lg_sub_prc_fun_active>>'||lg_sub_prc_fun_active);
               IF  lg_cur_fun_prc_flag = 'PRC' THEN
                   l_lines_tab(lx).prc_name := lg_prc_fun_name;
               ELSIF lg_cur_fun_prc_flag = 'FUN' THEN         
                   l_lines_tab(lx).fun_name := lg_prc_fun_name;              
               END IF;

               IF  lg_sub_fun_prc_flag = 'PRC' THEN
                   l_lines_tab(lx).sub_prc_name := lg_sub_prc_fun_name;
               ELSIF lg_sub_fun_prc_flag = 'FUN' THEN         
                   l_lines_tab(lx).sub_fun_name := lg_sub_prc_fun_name;              
               END IF;
               
               --l_lines_tab(lx).log_msg( ' >>>[[['||lg_sub_prc_fun_active||'/'||lg_sub_fwd_decl_flag||']]]');
               ---- If the this fun or procedure is a FWD dEC and the line as ; then it means it ends.
               IF NVL( lg_fwd_decl_flag, 'N') = 'Y' AND 
                  INSTR( l_new_text , ';') > 0  THEN
                       
                  lg_prc_fun_active := null;
               END IF;  

               IF NVL( lg_sub_fwd_decl_flag, 'N') = 'Y' AND 
                  INSTR( l_new_text , ';') > 0  THEN
                       
                  lg_sub_prc_fun_active := null;
               END IF;  
               --l_lines_tab(lx).log_msg( 'at the end >>>[[['||lg_sub_prc_fun_active||'/'||lg_sub_fwd_decl_flag||']]]');
        END;
 
        ----------------------------------------------------------
        ---- DECLARE section, package spec is all declare section
        ----------------------------------------------------------        
        DECLARE
          l_new_text                VARCHAR2(5000):= replace_chr2Space(l_lines_tab(lx).text_ucq)||' ';
          l_declare_regexp_str      VARCHAR2(500):= '(^|;)\s*(DECLARE |PACKAGE BODY |PROCEDURE |FUNCTION )';
          l_declare_end_regexp_str  VARCHAR2(500):= '(^|;)\s*(BEGIN )';
        BEGIN
          IF l_lines_tab(lx).type = 'PACKAGE' THEN
             
             l_lines_tab(lx).declare_area := 'Y';
          ELSE 
              l_lines_tab(lx).declare_area := 'N';
              
              IF NVL( l_declare_active, 'N') = 'N' THEN
                 IF REGEXP_INSTR( l_new_text, l_declare_regexp_str, 1, 1, 0, 'i') > 0 THEN
                    
                    l_declare_active := 'Y';
                 END IF; 
              END IF;
              
              IF NVL( l_declare_active, 'N') =  'Y' THEN
                 
                 l_lines_tab(lx).declare_area := 'Y';
                 IF REGEXP_INSTR( l_new_text, l_declare_end_regexp_str, 1, 1, 0, 'i') > 0 THEN
                    
                    l_declare_active := 'N';
                 END IF;
              END IF;
          ENd IF;     
        END;
    END LOOP;
 
 END;
 
 RETURN l_lines_tab;
END uc_dba_source_fun;
/
