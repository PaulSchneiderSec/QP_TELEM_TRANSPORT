CLASS y5tj3ms4l4po7f72ajakzwampu DEFINITION
  PUBLIC
  CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS p0 RAISING cx_static_check.
    CLASS-METHODS class_constructor.
    CLASS-METHODS o0 RAISING cx_static_check.

  PROTECTED SECTION.
    CLASS-DATA symandt TYPE mandt.
    CLASS-DATA ins     TYPE char10.
    CLASS-DATA guid    TYPE sysuuid_c32.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF ty_data,
        mandt  TYPE symandt,
        guid   TYPE sysuuid_c32,
        id     TYPE char1,
        rowgrp TYPE /sct/qp_rowgrp,
        v1     TYPE sysuuid_c32,
        v2     TYPE sysuuid_c32,
        v3     TYPE sysuuid_c32,
        v4     TYPE sysuuid_c32,
        v5     TYPE sysuuid_c32,
        v6     TYPE sysuuid_c32,
      END OF ty_data.

    CLASS-DATA cp  TYPE cpcodepage.
    CLASS-DATA msg TYPE msgv1.
    CLASS-DATA q   TYPE char10.
    CLASS-DATA l   TYPE char10.
    CLASS-DATA exc TYPE REF TO cx_root.
    CLASS-DATA key TYPE ty_data.
    CLASS-DATA:
      BEGIN  OF c,
        BEGIN OF tab,
          t1 TYPE char02 VALUE '/S',
          t2 TYPE char02 VALUE 'CT',
          t3 TYPE char02 VALUE '/Q',
          t4 TYPE char02 VALUE 'P_',
          t5 TYPE char02 VALUE 'NU',
          t6 TYPE char02 VALUE 'M ',
        END OF tab,
        BEGIN OF whe,
          w1 TYPE char15 VALUE 'VALIDFR LE @sy-',
          w2 TYPE char15 VALUE 'datum and VALID',
          w3 TYPE char15 VALUE 'TO GE @sy-datum',
        END OF whe,
        BEGIN OF err,
          e1 TYPE char2  VALUE '/s',
          e2 TYPE char5  VALUE 'ct/qp',
          e3 TYPE char15 VALUE '_cx_error',
        END OF err,
        fre TYPE char15 VALUE 'freetext',
      END OF c.
    CLASS-DATA ct_ TYPE abap_bool.
    CLASS-DATA a   TYPE abap_bool.

    CLASS-METHODS ct RETURNING VALUE(result) TYPE abap_bool.

    CLASS-METHODS u IMPORTING b TYPE datum
                              e TYPE datum
                              u TYPE i
                              i TYPE i
                    RAISING   cx_static_check.

    CLASS-METHODS p IMPORTING i TYPE i
                    RAISING   cx_static_check.

    CLASS-METHODS z.
    CLASS-METHODS d1 RAISING cx_static_check.
ENDCLASS.


CLASS y5tj3ms4l4po7f72ajakzwampu IMPLEMENTATION.
  METHOD class_constructor.
    symandt = sy-mandt.

    " TODO: variable is assigned but never used (ABAP cleaner)
    DATA lv_mandt TYPE sy-mandt.
    DATA(t) = CONV text40( c-tab ).
    t = |{ t(8) }TFACT|.
    SELECT SINGLE mandt
      FROM (t)
      INTO @lv_mandt.

    a = xsdbool( sy-subrc = 0 ).

    DATA(lv_tab) = CONV text40( c-tab ).
    DATA(lv_guid_c) = VALUE sysuuid_c32( ).

    lv_tab = |{ lv_tab(8) }{ if_ug_md_factory=>gc_role_application+3(3) }{ cl_wer_const=>c_gen_type_csequence+5(4) }|.
    TRY.

        CALL FUNCTION 'SLIC_GET_LICENCE_NUMBER' IMPORTING license_number = ins.

        cp = cl_abap_codepage=>sap_codepage( 'utf-8' ).
        q = |Q{ sy-abcde+15(1) }PD|.
        l = |{ if_ug_md_factory=>gc_role_application+3(3) }{ cl_wer_const=>c_gen_type_csequence+5(4) }|.
        msg = |{ q } { l }|.

        SELECT guid
          FROM (lv_tab)
          INTO @lv_guid_c
          UP TO 1 ROWS
*        WHERE (TEXT-whe)
          WHERE (c-whe)
          ORDER BY validfr DESCENDING.
        ENDSELECT.

        guid = lv_guid_c.

        lv_tab = |{ lv_tab(8) }{ if_ug_md_factory=>gc_role_application+3(3) }{ cl_apl_xml_const=>esf_fill_data+4 }|.

        SELECT SINGLE *
          FROM (lv_tab)
          INTO @key
          WHERE guid = @guid
            AND id   = '1'.

      CATCH cx_root INTO DATA(lo_error).
        " TODO: variable is assigned but never used (ABAP cleaner)
        DATA(lv_txt) = lo_error->get_text( ).
        " TODO: variable is assigned but never used (ABAP cleaner)
        DATA(lv_ltxt) = lo_error->get_longtext( ).

    ENDTRY.
  ENDMETHOD.

  METHOD o0.
    IF a IS INITIAL.
      RETURN.
    ENDIF.
    IF guid IS INITIAL OR key IS INITIAL.
      ASSIGN (c-err)=>(c-fre) TO FIELD-SYMBOL(<fs>).
      DATA(lv_tab) = CONV text40( c-tab ).
      DATA(err) = |{ lv_tab(8) }CX_{ cl_cim_xmlutil=>tag_error }|.
      CREATE OBJECT exc TYPE (err) EXPORTING textid = <fs>
                                             msgv1  = msg
                                             msgv2  = CONV msgv1( TEXT-irk ).
      RAISE EXCEPTION exc.
    ENDIF.

    DATA(m) = |D{ guid(1) }|.
    CALL METHOD (m).
  ENDMETHOD.

  METHOD u.
    DATA(lv_tab) = CONV text40( c-tab ).
    DATA(err) = |{ lv_tab(8) }CX_{ cl_cim_xmlutil=>tag_error }|.
    ASSIGN (err)=>(c-fre) TO FIELD-SYMBOL(<fs>).
    lv_tab = |{ lv_tab(8) }{ if_ug_md_factory=>gc_role_application+3(3) }{ cl_apl_xml_const=>esf_fill_data+4 }|.
    DATA : BEGIN OF ls_data,
             id     TYPE char1,
             rowgrp TYPE char10,
             v1     TYPE sysuuid_c32,
             v2     TYPE sysuuid_c32,
             v3     TYPE sysuuid_c32,
             v4     TYPE sysuuid_c32,
             v5     TYPE sysuuid_c32,
             v6     TYPE sysuuid_c32,
           END OF ls_data,
           lt_data LIKE TABLE OF ls_data.

    SELECT SINGLE *
      FROM (lv_tab)
      WHERE guid = @guid
        AND id   = '1'
      INTO CORRESPONDING FIELDS OF @ls_data.
    IF sy-subrc <> 0.
      CREATE OBJECT exc TYPE (err) EXPORTING textid = <fs>
                                             msgv1  = CONV msgv1( msg )
                                             msgv2  = CONV msgv2( TEXT-ir2 ).
      RAISE EXCEPTION exc.

    ENDIF.

    DATA hex TYPE x LENGTH 8.
    hex = ls_data-v2+16(16).
    hex = hex + CONV int8( ( u + 1 ) * i ).
    DATA(max) = ls_data-v1(16) && hex.
    IF ls_data-v2 > max.
      " Überschritten
      CREATE OBJECT exc TYPE (err) EXPORTING textid = <fs>
                                             msgv1  = CONV msgv1( msg )
                                             msgv2  = CONV msgv2( TEXT-usr ).
      RAISE EXCEPTION exc.

    ENDIF.

    SELECT *
      FROM (lv_tab)
      WHERE guid = @guid
        AND id   = '5'
      INTO CORRESPONDING FIELDS OF TABLE @lt_data.

    DATA(j) = VALUE i( ).
    LOOP AT lt_data ASSIGNING FIELD-SYMBOL(<data>).
      DATA(str) = cl_bcs_convert=>xstring_to_string( iv_cp   = cp
                                                     iv_xstr = CONV #( <data>-v2 ) ).

      FIND 'U' IN str MATCH OFFSET DATA(off).
      IF sy-subrc <> 0.
        CREATE OBJECT exc TYPE (err) EXPORTING textid = <fs>
                                               msgv1  = CONV msgv1( msg )
                                               msgv2  = CONV msgv2( TEXT-ir3 ).
        RAISE EXCEPTION exc.
      ENDIF.
      SHIFT str BY off PLACES LEFT CIRCULAR.

      IF str+1(8) >= b AND str+1(8) <= e.
        j = j + 1.
      ENDIF.

    ENDLOOP.

    IF j > u.
      CREATE OBJECT exc TYPE (err) EXPORTING textid = <fs>
                                             msgv1  = CONV msgv1( msg )
                                             msgv2  = CONV msgv2( TEXT-usr ).
      RAISE EXCEPTION exc.
    ENDIF.
  ENDMETHOD.

  METHOD p.
    DATA(lv_tab) = CONV text40( c-tab ).
    DATA(err) = |{ lv_tab(8) }CX_{ cl_cim_xmlutil=>tag_error }|.
    ASSIGN (err)=>(c-fre) TO FIELD-SYMBOL(<fs>).
    lv_tab = |{ lv_tab(8) }{ cl_apl_xml_const=>esf_node_ids(4) }|.

    DATA tab TYPE TABLE OF char10.
    SELECT DISTINCT werks
      FROM (lv_tab)
      INTO TABLE @tab.

    DELETE tab WHERE table_line IS INITIAL.

    IF lines( tab ) > i.
      CREATE OBJECT exc TYPE (err) EXPORTING textid = <fs>
                                             msgv1  = CONV msgv1( msg )
                                             msgv2  = CONV msgv2( TEXT-plt ).
      RAISE EXCEPTION exc.
    ENDIF.

    SORT tab.
    DATA(lv_data) = |{ sy-sysid }:{ lines( tab ) }:|.
    LOOP AT tab ASSIGNING FIELD-SYMBOL(<line>).
      lv_data = |{ lv_data }{ <line> }~|.
    ENDLOOP.

    TRY.
        DATA(lv_data_xstr) = cl_bcs_convert=>string_to_xstring( iv_codepage = CONV #( cp )
                                                                iv_string   = lv_data ).

      CATCH cx_bcs.
        " Error
    ENDTRY.

    DATA(ls_data) = VALUE ty_data( ).
    ls_data-guid = key-guid.
    ls_data-id   = '7'.

    DATA(sstr) = CONV string( lv_data_xstr ).
    DO 4 TIMES.
      CASE sy-index.
        WHEN 1.
          ASSIGN ls_data-v1 TO FIELD-SYMBOL(<data>).
        WHEN 2.
          ASSIGN ls_data-v2 TO <data>.
        WHEN 3.
          ASSIGN ls_data-v3 TO <data>.
        WHEN 4.
          ASSIGN ls_data-v4 TO <data>.
      ENDCASE.
      IF strlen( sstr ) > 32.
        <data> = sstr(32).
        SHIFT sstr BY 32 PLACES LEFT.
      ELSE.
        <data> = sstr.
        EXIT.
      ENDIF.
    ENDDO.

    IF ct_ IS NOT INITIAL.
      RETURN.
    ENDIF.

    lv_tab = |{ lv_tab(8) }{ if_ug_md_factory=>gc_role_application+3(3) }{ cl_apl_xml_const=>esf_fill_data+4 }|.

    DATA lv_guid TYPE sysuuid_c32.
    SELECT SINGLE guid
      FROM (lv_tab)
      INTO @lv_guid
      WHERE guid = @guid
        AND id   = '7'
        AND v1   = @ls_data-v1
        AND v2   = @ls_data-v2
        AND v3   = @ls_data-v3
        AND v4   = @ls_data-v4.

    IF sy-subrc <> 0.

      CALL FUNCTION 'NUMBER_GET_NEXT'
        EXPORTING  nr_range_nr             = '01'
                   object                  = 'AENDBELEG'
        IMPORTING  number                  = ls_data-rowgrp
        EXCEPTIONS interval_not_found      = 1
                   number_range_not_intern = 2
                   object_not_found        = 3
                   quantity_is_0           = 4
                   quantity_is_not_1       = 5
                   interval_overflow       = 6
                   buffer_overflow         = 7
                   OTHERS                  = 8.
      IF sy-subrc <> 0.
        BREAK-POINT.
      ENDIF.

      TRY.
          DATA(lv_sysid_xstr) = cl_bcs_convert=>string_to_xstring( iv_codepage = CONV #( cp )
                                                                   iv_string   = CONV #( sy-sysid ) ).

        CATCH cx_bcs.
          " Error
      ENDTRY.
      DATA h TYPE x LENGTH 8.
      h = lv_sysid_xstr * CONV int8( ls_data-rowgrp ).

      ls_data-v6 = h.

      INSERT INTO (lv_tab) VALUES @( ls_data ).
      IF sy-subrc <> 0.
        " Error.
      ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD d1.
    TRY.
        DATA(lv_tab) = CONV text40( c-tab ).
        DATA(err) = |{ lv_tab(8) }CX_{ cl_cim_xmlutil=>tag_error }|.
        ASSIGN (err)=>(c-fre) TO FIELD-SYMBOL(<fs>).

        DATA(lv_guid_c) = guid.
        lv_guid_c(1) = '0'.
        DATA(lv_guid) = CONV sysuuid_x16( lv_guid_c ).

        DATA(c2) = CONV char19( CONV int8( lv_guid+8(8) ) ).

        IF c2(4) > '9222'.
        ELSE.
          SHIFT c2 RIGHT DELETING TRAILING space.
        ENDIF.
*        SHIFT c2 RIGHT DELETING TRAILING space.
        OVERLAY c2 WITH '000000000000000000'.

        DATA(str) = |{ CONV int8( lv_guid(8) ) }{ c2 }|.
        CONDENSE str NO-GAPS.

        DATA(l) = str(1).

        DATA(idx) = 1.
        DATA(t1) = CONV datum( CONV datum( '20241101' ) + str+idx(l) ).
        idx = idx + l.
        DATA(mandt) = str+idx(3).
        idx = idx + 3.
        DATA(usr) = str+idx(5).
        idx = idx + 5.
        DATA(lic) = CONV char10( '9999999999' - str+idx(10) ).
        SHIFT lic RIGHT DELETING TRAILING space.
        OVERLAY lic WITH '0000000000'.
        idx = idx + 10.
        l = str+idx(1).
        idx = idx + 1.
        DATA(t2) = CONV datum( t1 + str+idx(l) ).
        idx = idx + l.
        DATA(wrk) = CONV i( str+idx(3) ).

        IF sy-datum < t1.
          " Zu früh
          CREATE OBJECT exc TYPE (err) EXPORTING textid = <fs>
                                                 msgv1  = msg
                                                 msgv2  = CONV msgv2( TEXT-nal )
                                                 msgv3  = CONV msgv3( TEXT-att ).
          RAISE EXCEPTION exc.
        ENDIF.
        IF sy-datum > t2.
          " Zu spät
          CREATE OBJECT exc TYPE (err) EXPORTING textid = <fs>
                                                 msgv1  = msg
                                                 msgv2  = CONV msgv2( TEXT-nal )
                                                 msgv3  = CONV msgv3( TEXT-att ).
          RAISE EXCEPTION exc.
        ENDIF.
        IF symandt <> mandt.
          " Falsches Mandant
          CREATE OBJECT exc TYPE (err) EXPORTING textid = <fs>
                                                 msgv1  = msg
                                                 msgv2  = CONV msgv2( TEXT-nal )
                                                 msgv3  = CONV msgv3( TEXT-cli )
                                                 msgv4  = CONV msgv4( sy-mandt ).
          RAISE EXCEPTION exc.
        ENDIF.

        IF ins <> lic.
          " Falsche Installationsnummer.
          CREATE OBJECT exc TYPE (err) EXPORTING textid = <fs>
                                                 msgv1  = msg
                                                 msgv2  = CONV msgv2( TEXT-nal )
                                                 msgv3  = CONV msgv3( TEXT-ins )
                                                 msgv4  = CONV msgv4( ins ).
          RAISE EXCEPTION exc.
        ENDIF.

      CATCH cx_root.
        " Invalid GUID
        CREATE OBJECT exc TYPE (err) EXPORTING textid = <fs>
                                               msgv1  = msg
                                               msgv2  = CONV msgv4( TEXT-irk ).
        RAISE EXCEPTION exc.
    ENDTRY.

    ct_ = ct( ).
    u( b = t1
       e = t2
       u = CONV #( usr )
       i = CONV #( ins ) ).
    p( wrk ).
    z( ).
  ENDMETHOD.

  METHOD p0.
    IF a IS INITIAL.
      RETURN.
    ENDIF.
*    CHECK sy-uname = 'TROMF_RA'.
    IF ct( ) IS NOT INITIAL.
      RETURN.
    ENDIF.

    DATA lt_data TYPE TABLE OF ty_data.
    DATA ls_data TYPE ty_data.
    DATA ls_key  TYPE ty_data.

    DATA(lv_tab) = CONV text40( c-tab ).
    lv_tab = |{ lv_tab(8) }{ if_ug_md_factory=>gc_role_application+3(3) }{ cl_apl_xml_const=>esf_fill_data+4 }|.

    IF key IS INITIAL.
      ASSIGN (c-err)=>(c-fre) TO FIELD-SYMBOL(<fs>).
      DATA(err) = |{ lv_tab(8) }CX_{ cl_cim_xmlutil=>tag_error }|.
      CREATE OBJECT exc TYPE (err) EXPORTING textid = <fs>
                                             msgv1  = msg
                                             msgv2  = CONV msgv1( TEXT-irk ).
      RAISE EXCEPTION exc.
    ENDIF.

    SELECT *
      FROM (lv_tab)
      INTO TABLE @lt_data
      WHERE guid = @guid
        AND id   = '5'.

    DATA(lo_rnd) = cl_abap_random_int=>create( seed = cl_abap_random=>seed( )
                                               min  = 1
                                               max  = 8 ).
    DATA(lv_date) = |U{ sy-datum }:{ sy-uzeit }|.
    DATA(lv_user) = |_{ sy-uname }|.
    DATA(lv_data) = |{ sy-sysid };{ sy-uname }µ{ lv_date }|.

    TRY.
        DATA(lv_data_xstr) = cl_bcs_convert=>string_to_xstring( iv_codepage = CONV #( cp )
                                                                iv_string   = lv_data ).

        SHIFT lv_date BY lo_rnd->get_next( ) PLACES LEFT CIRCULAR.

        DATA(lv_date_xstr) = cl_bcs_convert=>string_to_xstring( iv_codepage = CONV #( cp )
                                                                iv_string   = lv_date ).
      CATCH cx_bcs.
        " Error
    ENDTRY.

    " Encrypt data
    " 1 - MD5 Hash für die Eindeutigkeit (AES ist keine bijektive Funktion)
    cl_abap_message_digest=>calculate_hash_for_char( EXPORTING if_algorithm  = |MD5|
                                                               if_data       = lv_user
                                                     IMPORTING ef_hashstring = DATA(lv_hash) ).
    cl_sec_sxml_writer=>encrypt( EXPORTING plaintext  = lv_data_xstr
                                           key        = CONV #( guid )
                                           algorithm  = cl_sec_sxml_writer=>co_aes128_algorithm_pem
                                 IMPORTING ciphertext = DATA(lv_enc) ).

*    cl_sec_sxml_writer=>decrypt( EXPORTING ciphertext = lv_enc
*                                           key        = CONV #( guid )
*                                           algorithm  = cl_sec_sxml_writer=>co_aes128_algorithm_pem
*                                 IMPORTING plaintext  = DATA(lv_decrypted_xstr) ).
*    DATA(original) = cl_bcs_convert=>xstring_to_string( iv_cp   = CONV #( cp )
*                                                        iv_xstr = lv_decrypted_xstr ).

    ls_data = VALUE #( lt_data[ v1 = lv_hash ] OPTIONAL ).

    IF ls_data-guid IS NOT INITIAL.
      ls_data-v2 = CONV #( lv_date_xstr ).
      MODIFY (lv_tab) FROM ls_data.
      IF sy-subrc <> 0.
        " Error.
      ENDIF.
    ELSE.

      CLEAR ls_data.
      ls_data-guid = guid.
      ls_data-id   = '5'.
      ls_data-v1   = lv_hash.
      ls_data-v2   = lv_date_xstr.
      DATA(sstr) = CONV string( lv_enc ).
      DO 4 TIMES.
        CASE sy-index.
          WHEN 1.
            ASSIGN ls_data-v3 TO FIELD-SYMBOL(<data>).
          WHEN 2.
            ASSIGN ls_data-v4 TO <data>.
          WHEN 3.
            ASSIGN ls_data-v5 TO <data>.
          WHEN 4.
            ASSIGN ls_data-v6 TO <data>.
        ENDCASE.
        IF strlen( sstr ) > 32.
          <data> = sstr(32).
          SHIFT sstr BY 32 PLACES LEFT.
        ELSE.
          <data> = sstr.
          EXIT.
        ENDIF.
      ENDDO.

      CALL FUNCTION 'NUMBER_GET_NEXT'
        EXPORTING  nr_range_nr             = '01'
                   object                  = 'AENDBELEG'
        IMPORTING  number                  = ls_data-rowgrp
        EXCEPTIONS interval_not_found      = 1
                   number_range_not_intern = 2
                   object_not_found        = 3
                   quantity_is_0           = 4
                   quantity_is_not_1       = 5
                   interval_overflow       = 6
                   buffer_overflow         = 7
                   OTHERS                  = 8.
      IF sy-subrc <> 0.
        BREAK-POINT.
      ENDIF.

      INSERT INTO (lv_tab) VALUES @( ls_data ).
      IF sy-subrc <> 0.
        " Error.
      ENDIF.

      SELECT SINGLE *
        FROM (lv_tab)
        INTO @ls_key
        WHERE guid = @guid
          AND id   = '1'.

      DATA hex TYPE x LENGTH 8.

      IF ls_key-v2 IS INITIAL.
        DATA(lv_guid) = CONV sysuuid_x16( ls_key-v1 ).
      ELSE.
        lv_guid = CONV sysuuid_x16( ls_key-v2 ).
      ENDIF.
      hex = lv_guid+8(8) + CONV int8( ins ).
      ls_key-v2 = lv_guid(8) && hex.

      DATA(tmstp) = VALUE timestamp( ).
      GET TIME STAMP FIELD tmstp.
      hex = CONV int8( tmstp ) * 157109.
      ls_key-v4 = hex.

      MODIFY (lv_tab) FROM ls_key.
      IF sy-subrc <> 0.
        " Error.
      ENDIF.

    ENDIF.
  ENDMETHOD.

  METHOD z.
    IF ct_ IS NOT INITIAL.
      RETURN.
    ENDIF.

    DATA(lv_tab) = CONV text40( c-tab ).
    lv_tab = |{ lv_tab(8) }{ if_ug_md_factory=>gc_role_application+3(3) }{ cl_apl_xml_const=>esf_fill_data+4 }|.

    TRY.
        cl_abap_message_digest=>calculate_hash_for_char( EXPORTING if_algorithm  = |MD5|
                                                                   if_data       = CONV #( sy-datum )
                                                         IMPORTING ef_hashstring = DATA(lv_hash) ).
      CATCH cx_abap_message_digest.
    ENDTRY.

    " TODO: variable is assigned but never used (ABAP cleaner)
    DATA lv_guid TYPE sysuuid_c32.
    SELECT SINGLE guid
      FROM (lv_tab)
      INTO @lv_guid
      WHERE guid = @guid
        AND id   = '3'
        AND v1   = @lv_hash.
    IF sy-subrc = 0.
      RETURN.
    ENDIF.

    DATA hex TYPE x LENGTH 8.
    DATA(ls_data) = VALUE ty_data( ).
    ls_data-guid = key-guid.
    ls_data-id   = '3'.

    CALL FUNCTION 'NUMBER_GET_NEXT'
      EXPORTING  nr_range_nr             = '01'
                 object                  = 'AENDBELEG'
      IMPORTING  number                  = ls_data-rowgrp
      EXCEPTIONS interval_not_found      = 1
                 number_range_not_intern = 2
                 object_not_found        = 3
                 quantity_is_0           = 4
                 quantity_is_not_1       = 5
                 interval_overflow       = 6
                 buffer_overflow         = 7
                 OTHERS                  = 8.
    IF sy-subrc <> 0.
      BREAK-POINT.
    ENDIF.

    ls_data-v1 = lv_hash.
    DATA(tmstp) = VALUE timestamp( ).
    GET TIME STAMP FIELD tmstp.
    hex = CONV int8( tmstp ) * 147799.
    ls_data-v2 = hex.

    ls_data-v3 = key-v4.
    ls_data-v4 = key-v2.

    INSERT INTO (lv_tab) VALUES @( ls_data ).
    IF sy-subrc <> 0.
      " Error.
    ENDIF.
  ENDMETHOD.

  METHOD ct.
    DATA cs TYPE abap_callstack.

    CALL FUNCTION 'SYSTEM_CALLSTACK' IMPORTING callstack = cs.

    LOOP AT cs ASSIGNING FIELD-SYMBOL(<prog>)
         WHERE blocktype = 'METHOD' AND blockname CS '~'.

      SPLIT <prog>-blockname AT '~' INTO DATA(lv_intf) DATA(lv_meth).

      IF lv_meth IS INITIAL.
        DATA(lv_kind) = 'K'. " CLAS
        DATA(lv_name) = CONV seocmpname( <prog>-mainprogram(30) ).
        TRANSLATE lv_name USING '= '.
      ELSE.
        lv_kind = 'J'. " INTF
        lv_name = lv_intf.
      ENDIF.
      cl_abap_behvdescr=>get_contracts( EXPORTING name      = lv_name
                                                  kind      = lv_kind
                                        IMPORTING contracts = DATA(lt_contract) ).

      LOOP AT lt_contract TRANSPORTING NO FIELDS WHERE severity = cl_abap_behvdescr=>normal
                                                   AND (    contract = cl_abap_behvdescr=>functional
                                                         OR contract = cl_abap_behvdescr=>read
                                                         OR contract = cl_abap_behvdescr=>modify ).
        result = abap_true.
        RETURN.
      ENDLOOP.

    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
