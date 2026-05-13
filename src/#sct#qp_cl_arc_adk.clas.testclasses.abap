*CLASS ltc_arc_adk DEFINITION FINAL FOR TESTING
*  INHERITING FROM /sct/qp_cl_test
*  DURATION LONG
*  RISK LEVEL HARMLESS.
*
*  PROTECTED SECTION.
**   Test Methods
*    METHODS:
*      close                     FOR TESTING RAISING cx_static_check,
*      get_information_new       FOR TESTING RAISING cx_static_check,
*      get_information_existing  FOR TESTING RAISING cx_static_check,
*      perform_write_single      FOR TESTING RAISING cx_static_check,
*      is_session_active         FOR TESTING RAISING cx_static_check,
*      open_for_read_doc         FOR TESTING RAISING cx_static_check,
*      open_for_read_file        FOR TESTING RAISING cx_static_check,
*      open_for_delete         FOR TESTING RAISING cx_static_check,
*      open_for_restore         FOR TESTING RAISING cx_static_check,
*      perform_write_multi       FOR TESTING RAISING cx_static_check,
*      perform_read_multi        FOR TESTING RAISING cx_static_check,
*      read_data_object          FOR TESTING RAISING cx_static_check,
*      close_after_read          FOR TESTING RAISING cx_static_check,
*      protocol_init             FOR TESTING RAISING cx_static_check.
**   Helper Methods
*    CLASS-METHODS:
*      write_into_file RAISING cx_static_check,
*      open_for_write RAISING cx_static_check.
*  PRIVATE SECTION.
*    CLASS-DATA: mo_adk           TYPE REF TO lcl_adk.
*    TYPES: BEGIN OF s_node_data_db,
*             guid    TYPE /sct/qp_guid,
*             data_db TYPE /sct/qp_s_data_db,
*           END OF s_node_data_db,
*               t_node_data_db    TYPE STANDARD TABLE OF s_node_data_db WITH KEY guid.
*    CLASS-DATA mt_created_nodes  TYPE t_node_data_db.
*    CLASS-DATA mv_last_file_key  TYPE lcl_adk=>arc_file_key.
*    CLASS-DATA mv_class_file_key TYPE lcl_adk=>arc_file_key.
**   Fixture Methods
*    METHODS:
*      setup RAISING cx_static_check,
*      teardown RAISING cx_static_check.
*    CLASS-METHODS class_setup.
*ENDCLASS.
*
*
*CLASS ltc_arc_adk IMPLEMENTATION.
*
*  METHOD setup.
*
*    mo_adk = NEW lcl_adk( iv_object = mc->arc_object_versions ).
*
*    cl_abap_unit_assert=>assert_not_initial( act = mo_adk->mv_object ).
*
*  ENDMETHOD.
*
*  METHOD teardown.
*
*    IF mo_adk->is_session_active( ) = abap_true.
*      mo_adk->close( ).
*    ENDIF.
*
*    NEW /sct/qp_cl_test_arc( )->delete_ut_nodes( ).
*    CLEAR mt_created_nodes.
*    /sct/qp_cl_qv_bus=>free( ).
*
*    CLEAR mo_adk.
*    CLEAR mv_last_file_key.
*
*  ENDMETHOD.
*
*  METHOD open_for_write.
*
**   We want to test true productive writing, so we disable test mode.
**   This is totally okay because instead we use a separate archiving object
**   all UT test data created here will be written to so that therefore no
**   productive archiving object is affected.
*    mo_adk->open_for_write( iv_test_mode = abap_false ).
*
*    cl_abap_unit_assert=>assert_not_initial( act = mo_adk->mv_handle ).
*    cl_abap_unit_assert=>assert_not_initial( act = mo_adk->mv_document ).
*
*  ENDMETHOD.
*
*  METHOD protocol_init.
*
*    mo_adk->protocol_init( iv_output = mc->arc_protocol_output_none ).
*
*    cl_abap_unit_assert=>assert_not_initial( act = mo_adk->mv_protocol_handle ).
*    cl_abap_unit_assert=>assert_equals( act = mo_adk->mv_protocol_output exp = mc->arc_protocol_output_none ).
*
*  ENDMETHOD.
*
*  METHOD write_into_file.
*
*    NEW /sct/qp_cl_test_arc( )->create_ut_nodes(
*      EXPORTING
*        iv_vname       = 'UT_ARC_ADK_' && cl_system_uuid=>create_uuid_c22_static( )
*        it_items       = VALUE #( ( vtyp = 'UT_VTYP' ) )
*      IMPORTING
*        es_base_root   = DATA(ls_base_root)
*        es_qvc_data_db = DATA(ls_qvc_data_db) ).
*
*    INSERT VALUE #( guid = ls_base_root-guid data_db = ls_qvc_data_db ) INTO TABLE mt_created_nodes.
*
*    mo_adk->new_object( iv_guid = ls_base_root-guid ).
*    cl_abap_unit_assert=>assert_equals( act = CONV /sct/qp_guid( mo_adk->mv_data_object ) exp = ls_base_root-guid ).
*
*    mo_adk->put_node_data( is_qv_data = ls_qvc_data_db ).
*
*    mo_adk->save_object( ).
*    cl_abap_unit_assert=>assert_not_initial( act = mo_adk->mv_file_key ).
*
*    mv_last_file_key = mo_adk->mv_file_key.
*
*  ENDMETHOD.
*
*  METHOD is_session_active.
*
*    cl_abap_unit_assert=>assert_false( act = mo_adk->is_session_active( ) ).
*
*    mo_adk->open_for_write( ).
*
*    cl_abap_unit_assert=>assert_true( act = mo_adk->is_session_active( ) ).
*
*  ENDMETHOD.
*
*
*  METHOD close.
*
*    mo_adk->open_for_write( ).
*
*    mo_adk->protocol_init( mc->arc_protocol_output_none ).
*
*    mo_adk->close( ).
*
*    cl_abap_unit_assert=>assert_initial( act = mo_adk->mv_data_object ).
*    cl_abap_unit_assert=>assert_initial( act = mo_adk->mv_file_key ).
*    cl_abap_unit_assert=>assert_initial( act = mo_adk->mv_handle ).
*    cl_abap_unit_assert=>assert_initial( act = mo_adk->mv_protocol_handle ).
*    cl_abap_unit_assert=>assert_initial( act = mo_adk->mv_protocol_output ).
*    cl_abap_unit_assert=>assert_false( act = mo_adk->is_session_active( ) ).
*
*  ENDMETHOD.
*
*  METHOD get_information_new.
*
*    me->open_for_write( ).
*
*    mo_adk->get_information(
*      IMPORTING
*        ev_creation_date   = DATA(lv_creation_date)
*        ev_creation_system = DATA(lv_creation_system)
*        ev_document        = DATA(lv_document)
*        ev_file_key        = DATA(lv_file_key)
*        ev_code_page       = DATA(lv_code_page)
*        ev_number_format   = DATA(lv_number_format)
*        ev_adk_version     = DATA(lv_adk_version) ).
*
*    cl_abap_unit_assert=>assert_initial( act = lv_creation_date   ).
*    cl_abap_unit_assert=>assert_not_initial( act = lv_creation_system ).
*    cl_abap_unit_assert=>assert_not_initial( act = lv_document ).
*    cl_abap_unit_assert=>assert_initial( act = lv_file_key ).
*    cl_abap_unit_assert=>assert_initial( act = lv_code_page ).
*    cl_abap_unit_assert=>assert_initial( act = lv_number_format ).
*    cl_abap_unit_assert=>assert_not_initial( act = lv_adk_version ).
*
*  ENDMETHOD.
*
*  METHOD get_information_existing.
*
*    me->open_for_write( ).
*    me->write_into_file( ).
*
*    mo_adk->get_information(
*      IMPORTING
*        ev_creation_date   = DATA(lv_creation_date)
*        ev_creation_system = DATA(lv_creation_system)
*        ev_document        = DATA(lv_document)
*        ev_file_key        = DATA(lv_file_key)
*        ev_code_page       = DATA(lv_code_page)
*        ev_number_format   = DATA(lv_number_format)
*        ev_adk_version     = DATA(lv_adk_version) ).
*
*    cl_abap_unit_assert=>assert_not_initial( act = lv_creation_date   ).
*    cl_abap_unit_assert=>assert_not_initial( act = lv_creation_system ).
*    cl_abap_unit_assert=>assert_not_initial( act = lv_document ).
*    cl_abap_unit_assert=>assert_not_initial( act = lv_file_key ).
*    cl_abap_unit_assert=>assert_not_initial( act = lv_code_page       ).
*    cl_abap_unit_assert=>assert_not_initial( act = lv_number_format   ).
*    cl_abap_unit_assert=>assert_not_initial( act = lv_adk_version ).
*
*  ENDMETHOD.
*
*  METHOD perform_write_single.
*
*    me->open_for_write( ).
*    me->write_into_file( ).
*    mo_adk->close( ).
*
*    mo_adk->get_files_of_session( IMPORTING et_archive_files = DATA(lt_archive_files) ).
*    cl_abap_unit_assert=>assert_equals( act = lines( lt_archive_files ) exp = 1 ).
*
*  ENDMETHOD.
*
*  METHOD perform_write_multi.
*
*    me->open_for_write( ).
*
*    me->write_into_file( ).
*    me->write_into_file( ).
*
*    mo_adk->close( ).
*
*    mo_adk->get_files_of_session( IMPORTING et_archive_files = DATA(lt_archive_files) ).
*    cl_abap_unit_assert=>assert_equals( act = lines( lt_archive_files ) exp = 1 ).
*
*  ENDMETHOD.
*
*  METHOD perform_read_multi.
*
*    me->perform_write_multi( ).
*
*    mo_adk->open_for_read(
*      iv_archive_document = mo_adk->mv_document
*      it_r_file_selection = VALUE #( ( sign = 'I' option = 'EQ' low = '*' ) ) ).
*
*    mo_adk->next_object( ).
*    DATA(lv_first_object) = mo_adk->mv_data_object.
*    mo_adk->get_node_data(
*      IMPORTING
*        es_data_db = DATA(ls_data_db_read) ).
*    cl_abap_unit_assert=>assert_equals( act = lines( ls_data_db_read-node ) exp = 2 ).
*    ASSIGN ls_data_db_read-node[ guid = mo_adk->mv_data_object ] TO FIELD-SYMBOL(<fs_qv>).
*    cl_abap_unit_assert=>assert_equals( act = sy-subrc exp = 0 ).
*
*    mo_adk->next_object( ).
*    DATA(lv_second_object) = mo_adk->mv_data_object.
*    mo_adk->get_node_data(
*      IMPORTING
*        es_data_db = DATA(ls_data_db_read_2) ).
*    cl_abap_unit_assert=>assert_equals( act = lines( ls_data_db_read_2-node ) exp = 2 ).
*    ASSIGN ls_data_db_read_2-node[ guid = mo_adk->mv_data_object ] TO <fs_qv>.
*    cl_abap_unit_assert=>assert_equals( act = sy-subrc exp = 0 ).
*
*    cl_abap_unit_assert=>assert_not_initial( act = lv_first_object ).
*    cl_abap_unit_assert=>assert_not_initial( act = lv_second_object ).
*    cl_abap_unit_assert=>assert_differs( act = lv_first_object exp = lv_second_object ).
*
*  ENDMETHOD.
*
*  METHOD open_for_read_doc.
*
*    me->perform_write_single( ).
*
**   Read all files for a single document
*
*    mo_adk->open_for_read(
*      iv_archive_document = mo_adk->mv_document
*      it_r_file_selection = VALUE #( ( sign = 'I' option = 'EQ' low = '*' ) ) ).
*
*    cl_abap_unit_assert=>assert_not_initial( act = mo_adk->mt_selected_files ).
*
*    cl_abap_unit_assert=>assert_not_initial( act = mo_adk->mv_handle ).
*    cl_abap_unit_assert=>assert_not_initial( act = mo_adk->mv_document ).
*
*  ENDMETHOD.
*
*  METHOD open_for_read_file.
*
*    me->perform_write_single( ).
*
**   Read single file without knowing the document
*
*    mo_adk->get_files_of_session( IMPORTING et_archive_files = DATA(lt_archive_files) ).
*
*    mo_adk->open_for_read(
*      it_r_file_selection = VALUE #( FOR <file> IN lt_archive_files
*        ( sign = 'I' option = 'EQ' low = <file>-archiv_key ) ) ).
*
*    cl_abap_unit_assert=>assert_not_initial( act = mo_adk->mt_selected_files ).
*
*    cl_abap_unit_assert=>assert_not_initial( act = mo_adk->mv_handle ).
*    cl_abap_unit_assert=>assert_initial( act = mo_adk->mv_document ).
*
*  ENDMETHOD.
*
*  METHOD read_data_object.
*
*    me->perform_write_multi( ).
*
*    mo_adk->open_for_read(
*      iv_archive_document = mo_adk->mv_document
*      it_r_file_selection = VALUE #( ( sign = 'I' option = 'EQ' low = '*' ) ) ).
*
*    ASSIGN mt_created_nodes[ 2 ] TO FIELD-SYMBOL(<fs_created_node>).
*    mo_adk->read_object( iv_object_id = CONV #( <fs_created_node>-guid ) ).
*
*    mo_adk->get_node_data( IMPORTING es_data_db = DATA(ls_qvc_data_db_read) ).
*
*    cl_abap_unit_assert=>assert_equals( act = ls_qvc_data_db_read exp = <fs_created_node>-data_db ).
*
*  ENDMETHOD.
*
*  METHOD close_after_read.
*
**   Just for experimental purposes. Close after read is possible and needed!
*
*    me->perform_write_single( ).
*
*    mo_adk->open_for_read(
*      iv_archive_document = mo_adk->mv_document
*      it_r_file_selection = VALUE #( ( sign = 'I' option = 'EQ' low = '*' ) ) ).
*
*    mo_adk->close( ).
*
*  ENDMETHOD.
*
*
*  METHOD open_for_delete.
*
**    DATA(ls_arcnode) = VALUE /sct/qp_arcnode( ).
**    SELECT SINGLE * FROM /sct/qp_arcnode INTO ls_arcnode WHERE arcid = 'UT_ARC_ADK' AND vname = 'TEST_ARC_ADK'.
**
**    IF sy-subrc <> 0.
**      cl_abap_unit_assert=>fail( msg = |Test node with VANME 'TEST_ARC_ADK' in ARCID 'UT_ARC_ADK' needed to perform.| ).
**    ENDIF.
**
**    mo_adk->open_for_delete( iv_file_key = ls_arcnode-arcfid iv_test_mode = abap_true ).
**
**    mo_adk->protocol_init( iv_output = mc->arc_protocol_output_bal ).
**
**    cl_abap_unit_assert=>assert_not_initial( mo_adk->mv_handle ).
*
*  ENDMETHOD.
*
*
*  METHOD class_setup.
*
**    mo_adk = NEW lcl_adk( iv_object = mc->arc_object_versions ).
**
**    TRY.
**        open_for_write( ).
**        write_into_file( ).
**        mo_adk->close( ).
**
**      CATCH cx_static_check INTO DATA(lx).
**        cl_abap_unit_assert=>fail( ).
**    ENDTRY.
**
**    mv_class_file_key = mv_last_file_key.
*
*  ENDMETHOD.
*
*
*  METHOD open_for_restore.
*
**   Not testable because only working in GUI mode
*
*  ENDMETHOD.
*
*ENDCLASS.
*
*
*CLASS ltc_arc_type DEFINITION FINAL FOR TESTING
*  INHERITING FROM /sct/qp_cl_test_arc_adk_type
*  DURATION LONG
*  RISK LEVEL HARMLESS.
*
*  PRIVATE SECTION.
*
*ENDCLASS.
*
*
*CLASS ltc_arc_type IMPLEMENTATION.
*
*ENDCLASS.
