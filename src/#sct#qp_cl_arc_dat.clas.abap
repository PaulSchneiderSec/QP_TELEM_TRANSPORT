CLASS /sct/qp_cl_arc_dat DEFINITION
  PUBLIC
  INHERITING FROM /sct/qp_cl_arc_adk FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES: BEGIN OF s_arc_file,
             name    TYPE strng250,
             size    TYPE i,
             header  TYPE xstring,
             datatab TYPE solix_tab,
             data    TYPE xstring,
           END OF s_arc_file,
           t_arc_file TYPE STANDARD TABLE OF s_arc_file WITH KEY name.

    CLASS-DATA mv_directory TYPE string READ-ONLY.

    METHODS /sct/qp_if_arc_type~get_type          REDEFINITION.
    METHODS /sct/qp_if_arc_type~open              REDEFINITION.
    METHODS /sct/qp_if_arc_type~read              REDEFINITION.
    METHODS /sct/qp_if_arc_type~write             REDEFINITION.
    METHODS /sct/qp_if_arc_type~write_customizing REDEFINITION.
    METHODS /sct/qp_if_arc_type~read_customizing  REDEFINITION.
    METHODS /sct/qp_if_arc_type~close             REDEFINITION.
    METHODS /sct/qp_if_arc_type~get_file_id       REDEFINITION.
    METHODS /sct/qp_if_arc_type~open_for_delete   REDEFINITION.

    CLASS-METHODS set_working_directory IMPORTING iv_directory TYPE /sct/qp_arc_filedir OPTIONAL.

  PROTECTED SECTION.
    DATA ms_arc        TYPE /sct/qp_arc.
    DATA mt_arcnode    TYPE /sct/qp_t_arcnode.
    DATA mt_arcnodet   TYPE /sct/qp_t_arcnodet.
    DATA mv_arc_action TYPE /sct/qp_arc_action.

    CLASS-METHODS build_file_path IMPORTING iv_directory       TYPE string
                                            iv_filename        TYPE string
                                  RETURNING VALUE(rv_filepath) TYPE string.

  PRIVATE SECTION.
    DATA mo_xml_buffer TYPE REF TO /sct/qp_cl_xml_buffer.
    DATA mv_filepath   TYPE string.
    DATA mv_filename   TYPE string.
ENDCLASS.


CLASS /sct/qp_cl_arc_dat IMPLEMENTATION.
  METHOD /sct/qp_if_arc_type~close.
    " --------------------------------------------------------------------*
    " Änderungslog
    " --------------------------------------------------------------------*
    " MD, 2018.07.16: N1885 Duplikate aus XML-Pufferdaten löschen
    " --------------------------------------------------------------------*
    " MD, 2020.12.18: N2368 Interface / Refactoring / Konstanten
    " --------------------------------------------------------------------*

    CASE mv_arc_action.

      WHEN mc->arc_action-write.

        DATA(lo_xml) = mo_xml_buffer->get( mv_filepath ).
        lo_xml->compact_tables( ). " MD180716 N1885 INS
        lo_xml->export_file( mv_filepath ).

    ENDCASE.
  ENDMETHOD.

  METHOD /sct/qp_if_arc_type~get_file_id ##NEEDED.
  ENDMETHOD.

  METHOD /sct/qp_if_arc_type~get_type.
    rv_arctype = mc->arctype_dat.
  ENDMETHOD.

  METHOD /sct/qp_if_arc_type~open.
    mv_arcid = is_arcnode-arcid.

    SELECT SINGLE * FROM /sct/qp_arc
      INTO ms_arc
      WHERE arcid = is_arcnode-arcid.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE /sct/qp_cx_error EXPORTING textid = /sct/qp_cx_error=>arc_arcid_not_found.
    ENDIF.

    set_working_directory( iv_directory = ms_arc-filedir ).

    mo_xml_buffer = /sct/qp_cl_xml_buffer=>get_instance( ).

    " The action to perform is remembered in attribute to be able to decide the closing action later on
    CASE iv_arc_action.

      WHEN mc->arc_action-write.

        mv_arc_action = mc->arc_action-write.

        GET TIME STAMP FIELD DATA(lv_cur_timestamp).
        mv_filename = |{ mv_arcid }_{ sy-sysid }_{ lv_cur_timestamp }.xml| ##NO_TEXT.
        mv_filepath = build_file_path( iv_directory = mv_directory
                                       iv_filename  = mv_filename ).

      WHEN mc->arc_action-read.

        mv_arc_action = mc->arc_action-read.

      WHEN mc->arc_action-restore.

      WHEN mc->arc_action-delete.

      WHEN mc->arc_action-mark_for_deletion.

    ENDCASE.
  ENDMETHOD.

  METHOD /sct/qp_if_arc_type~open_for_delete ##NEEDED.
  ENDMETHOD.

  METHOD /sct/qp_if_arc_type~read.
    " --------------------------------------------------------------------*
    "  Änderungslog
    " --------------------------------------------------------------------*
    "  AD, 2025.03.12, NOTE-3630
    "  Export-Parameter initialisieren
    " --------------------------------------------------------------------*
    CLEAR et_qvc_data.

    mv_filepath = build_file_path( iv_directory = mv_directory
                                   iv_filename  = CONV #( is_arcnode-filename ) ).

    mo_xml_buffer->open( mv_filepath )->get_arc_data( IMPORTING es_arcex_data = DATA(ls_arcex_data) ).

    es_db_data = CORRESPONDING #( ls_arcex_data ).
  ENDMETHOD.

  METHOD /sct/qp_if_arc_type~read_customizing.
    mo_xml_buffer->open( mv_filepath )->get_arc_data( IMPORTING es_cust_data = es_cust_db ).
  ENDMETHOD.

  METHOD /sct/qp_if_arc_type~write.
    es_arcnode = VALUE /sct/qp_arcnode( arcid       = mv_arcid
                                        guid        = is_root_select-guid
                                        arctype     = me->/sct/qp_if_arc_type~get_type( )
                                        arcformvers = mc_arcformvers
                                        filename    = mv_filename ).

    ASSIGN it_qvc_data[ guid = is_root_select-guid ] TO FIELD-SYMBOL(<fs_qv_data>).
    IF sy-subrc = 0.
      es_arcnode-info = CORRESPONDING #( <fs_qv_data> ) ##ENH_OK.
    ELSE.
      RAISE EXCEPTION TYPE /sct/qp_cx_error. " Specification info for ARCNODE is obligatory!
    ENDIF.

    DATA(ls_arcex_data) = CORRESPONDING /sct/qp_s_arcex_data( is_db_data ).
    INSERT ms_arc INTO TABLE ls_arcex_data-arc.
    ls_arcex_data-arcnode = VALUE #( ( es_arcnode ) ).
    mo_xml_buffer->get( mv_filepath )->set_arc_data( is_arcex_data = ls_arcex_data ).
  ENDMETHOD.

  METHOD /sct/qp_if_arc_type~write_customizing.
    mo_xml_buffer->get( mv_filepath )->set_arc_data( is_cust_data = is_cust_db ).
  ENDMETHOD.

  METHOD build_file_path.
    DATA(lv_directory) = iv_directory.
    IF lv_directory IS INITIAL.
      DATA(lv_sapgui_directory) = VALUE string( ).
      cl_gui_frontend_services=>get_sapgui_directory( CHANGING   sapgui_directory     = lv_sapgui_directory
                                                      EXCEPTIONS cntl_error           = 1
                                                                 not_supported_by_gui = 2
                                                                 error_no_gui         = 3
                                                                 OTHERS               = 4 ).
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE mc->msgtype_e NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
      lv_directory = lv_sapgui_directory.
    ENDIF.

    DATA(lv_directory_rev) = reverse( iv_directory ).
    DATA(lv_directory_ending) = lv_directory_rev(1).
    rv_filepath = |{ iv_directory }{
      COND #( WHEN lv_directory_ending <> mc->char_backslash
              THEN mc->char_backslash ) }{
      iv_filename }|.
  ENDMETHOD.

  METHOD set_working_directory.
    IF iv_directory IS INITIAL.

      DATA(lv_selected_folder) = VALUE string( ).
      cl_gui_frontend_services=>directory_browse( CHANGING   selected_folder      = lv_selected_folder
                                                  EXCEPTIONS cntl_error           = 1
                                                             error_no_gui         = 2
                                                             not_supported_by_gui = 3
                                                             OTHERS               = 4 ).
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE mc->msgtype_e NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.

      mv_directory = lv_selected_folder.

    ELSE.

      mv_directory = iv_directory.

    ENDIF.
  ENDMETHOD.
ENDCLASS.
