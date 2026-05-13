CLASS /sct/qp_cl_arc_adk DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.

    "! Archiving format version. Indicates the state of DDIC structures the archiving is performed with.
    "! This version number is saved along with ARCNODE entries on creation. If data is to be restored on
    "! a system, the value of this constant can be compared with the version of ARCNODE entries to
    "! restore to be warned about possible incompatibilities to the installed QPPD DDIC formats.
    CONSTANTS mc_arcformvers TYPE /sct/qp_arc_format_version VALUE '1.0'.

    INTERFACES:
      /sct/qp_if_arc_type.

    METHODS constructor
      RAISING
        /sct/qp_cx_error.

    TYPES: arc_object           TYPE objct_tr01,
           arc_handle           TYPE syst_tabix,
           arc_document         TYPE admi_run_d,
           arc_file_key         TYPE arkey,
           arc_data_object      TYPE datobj_id,
           arc_record_structure TYPE rkz_dbna,
           arc_protocol_handle  TYPE balloghndl,
           arc_log_detail       TYPE arch_detail_log,
           arc_log_msgtype      TYPE c LENGTH 1,
           arc_protocol_output  TYPE arch_obj_prot_output_2,
           data_map_direction   TYPE c LENGTH 1,
           BEGIN OF s_components,
             object      TYPE arc_object,
             document    TYPE arc_document,
             file_key    TYPE arc_file_key,
             data_object TYPE arc_data_object,
           END OF s_components,
           t_file           TYPE STANDARD TABLE OF admi_filen WITH DEFAULT KEY,
           t_file_key       TYPE STANDARD TABLE OF arch_files WITH DEFAULT KEY,
           r_file_key       TYPE STANDARD TABLE OF rng_archiv WITH DEFAULT KEY,
           t_document_file  TYPE STANDARD TABLE OF admi_files WITH DEFAULT KEY,
           t_init_structure TYPE STANDARD TABLE OF arch_ddic WITH DEFAULT KEY.

    CONSTANTS arc_log_detail_complete  TYPE arc_log_detail VALUE 'X'.
    CONSTANTS arc_log_detail_none      TYPE arc_log_detail VALUE ' '.
    CONSTANTS arc_log_detail_problems  TYPE arc_log_detail VALUE '1'.
    CONSTANTS data_map_direction_read  TYPE data_map_direction VALUE 'R'.
    CONSTANTS data_map_direction_write TYPE data_map_direction VALUE 'W'.

    DATA: mv_object          TYPE arc_object,
          mv_handle          TYPE arc_handle,
          mv_document        TYPE arc_document,
          mv_file_key        TYPE arc_file_key,
          mv_data_object     TYPE arc_data_object,
          mv_object_handle   TYPE arc_handle,
          mv_protocol_handle TYPE arc_protocol_handle,
          mv_protocol_output TYPE arc_protocol_output.
    DATA: mt_selected_files  TYPE t_document_file.

protected section.

  class-data MC type ref to /SCT/QP_CL_CONST .
  data MV_ARCID type /SCT/QP_ARCID .

  methods OPEN_FOR_WRITE
    importing
      !IV_TEST_MODE type ABAP_BOOL optional
      !IV_NO_DELETE type ABAP_BOOL optional
    raising
      /SCT/QP_CX_ERROR .
  methods OPEN_FOR_READ
    importing
      !IV_ARCHIVE_DOCUMENT type ARC_DOCUMENT optional
      !IT_R_FILE_SELECTION type R_FILE_KEY
    raising
      /SCT/QP_CX_ERROR .
    "! Open a session to delete data from DB.
    "! @parameter iv_file_key | If not given, files stored for job are used.
  methods OPEN_FOR_DELETE
    importing
      !IV_FILE_KEY type ARC_FILE_KEY optional
      !IV_TEST_MODE type ABAP_BOOL optional
    raising
      /SCT/QP_CX_ERROR .
  methods OPEN_FOR_RESTORE
    importing
      !IV_FILE_KEY type ARC_FILE_KEY
      !IV_TEST_MODE type ABAP_BOOL optional
    raising
      /SCT/QP_CX_ERROR .
    "! Close all currently opened files, save statistics and protocol.
    "! NOTE: Protocols written within aRFC calls will not be actually saved!
  methods CLOSE
    raising
      /SCT/QP_CX_ERROR .
    "! Close data object previously opened by offset using method READ_OBJECT.
  methods CLOSE_OBJECT
    raising
      /SCT/QP_CX_ERROR .
  methods GET_INFORMATION
    exporting
      !EV_CREATION_DATE type HEADA-DATUM
      !EV_CREATION_SYSTEM type HEADA-SYSID
      !EV_DOCUMENT type ADMI_RUN-DOCUMENT
      !EV_FILE_KEY type HEADA-ARKEY
      !EV_CODE_PAGE type TCP00-CPCODEPAGE
      !EV_NUMBER_FORMAT type TCP00-CPCODEPAGE
      !EV_ADK_VERSION type HEADA-SAPRL
    raising
      /SCT/QP_CX_ERROR .
  methods GET_FILES_OF_SESSION
    exporting
      !ET_ARCHIVE_FILES type T_FILE
    raising
      /SCT/QP_CX_ERROR .
  methods GET_FILES_OF_HANDLE
    exporting
      !ET_ARCHIVE_FILES type T_FILE_KEY
    raising
      /SCT/QP_CX_ERROR .
  methods IS_SESSION_ACTIVE
    returning
      value(RV_ACTIVE) type ABAP_BOOL .
  methods PUT_NODE_DATA
    importing
      !IS_QV_DATA type /SCT/QP_S_DB_DATA
    raising
      resumable(/SCT/QP_CX_ERROR) .
  methods GET_NODE_DATA
    importing
      !IV_FILE_KEY type ARC_FILE_KEY optional
      !IV_OBJECT_OFFSET type ADMI_OFFST optional
    exporting
      !ES_DB_DATA type /SCT/QP_S_DB_DATA
    raising
      resumable(/SCT/QP_CX_ERROR) .
  methods NEW_OBJECT
    importing
      !IV_GUID type /SCT/QP_GUID
    raising
      /SCT/QP_CX_ERROR .
  methods NEXT_OBJECT
    exporting
      !EV_END_OF_FILES type ABAP_BOOL
    raising
      /SCT/QP_CX_ERROR .
    "! Activate a single data object of current file handle for further reading.
    "! It is recommended to always pass FILE_KEY+OFFSET if possible, otherwise there
    "! will be a sequential read which means that you have to close the handle after
    "! each READ_OBJECT to reset the sequence pointer as otherwise it is possible to
    "! loose access to data actually existing.
  methods READ_OBJECT
    importing
      !IV_OBJECT_ID type ARC_DATA_OBJECT
      !IV_FILE_KEY type ARC_FILE_KEY optional
      !IV_OFFSET type ADMI_OFFST optional
    raising
      /SCT/QP_CX_ERROR .
  methods SAVE_OBJECT
    exporting
      !EV_OFFSET type ADMI_OFFST
    raising
      /SCT/QP_CX_ERROR .
  methods GET_ACTIVE_COMPONENTS
    returning
      value(RS_ACTIVE_COMPONENTS) type S_COMPONENTS .
    "! Add a single message to the session protocol.
    "! NOTE: Protocols written within aRFC calls will not be actually saved!
  methods PROTOCOL_COLLECT
    importing
      !IV_OBJECT type ANY optional
      !IV_TEXT type ANY optional
      !IV_MSGTYPE type ARC_LOG_MSGTYPE optional
      !IV_MSGID type SYST_MSGID default /SCT/QP_CL_CONST=>MSGID_SCTQP
      !IV_MSGNO type SYST_MSGNO optional
      !IV_MSGV1 type ANY optional
      !IV_MSGV2 type ANY optional
      !IV_MSGV3 type ANY optional
      !IV_MSGV4 type ANY optional .
  methods PROTOCOL_INIT
    importing
      !IV_OUTPUT type ARC_PROTOCOL_OUTPUT .
    "! Map init data structures in the given direction, reading from or writing to archive.
    "! <br/>The structures should be provided in one of the following ways:
    "! <br/>WRITE: Supply only IS_CUST
    "! <br/>READ: Supply only ES_CUST
    "! @parameter is_cust_db | Customizing data (Supply on WRITE)
    "! @parameter iv_direction | Mapping direction (Read or write)
    "! @parameter es_cust_db | Customizing data (Supply on READ)
  methods MAP_INIT_DATA
    importing
      !IS_CUST_DB type /SCT/QP_S_CUST_TAB_DB optional
      !IV_DIRECTION type DATA_MAP_DIRECTION
    exporting
      !ES_CUST_DB type /SCT/QP_S_CUST_TAB_DB
    raising
      resumable(/SCT/QP_CX_ERROR) .
  methods READ_FILE
    importing
      !IV_FILE_KEY type ARC_FILE_KEY
    raising
      /SCT/QP_CX_ERROR .
  PRIVATE SECTION.

    "! Write a single table into the active data object.
    "! @parameter it_table | Tabular data matching given record structure.
    "! @parameter iv_record_structure | One of the structures maintained in archiving object.
    METHODS put_table
      IMPORTING
        it_table            TYPE STANDARD TABLE
        iv_record_structure TYPE arc_record_structure
      RAISING
        RESUMABLE(/sct/qp_cx_error).

    "! Write a single table into the active data object.
    "! @parameter iv_record_structure | One of the structures maintained in archiving object.
    "! @parameter et_table | Tabular data matching given record structure.
    METHODS get_table
      IMPORTING
        iv_record_structure TYPE arc_record_structure
      EXPORTING
        et_table            TYPE STANDARD TABLE
      RAISING
        RESUMABLE(/sct/qp_cx_error).

    METHODS get_active_sessions EXPORTING et_active_sessions TYPE arch_t_sessions.

    METHODS get_init_structures
      EXPORTING
        et_init_structures TYPE t_init_structure
      RAISING
        /sct/qp_cx_error.

ENDCLASS.



CLASS /SCT/QP_CL_ARC_ADK IMPLEMENTATION.


  METHOD /sct/qp_if_arc_type~add_message.

    IF it_arc_return IS NOT INITIAL.
      DATA(lt_arc_return) = it_arc_return.
    ELSEIF is_arc_return IS NOT INITIAL.
      INSERT is_arc_return INTO TABLE lt_arc_return.
    ENDIF.

    LOOP AT lt_arc_return ASSIGNING FIELD-SYMBOL(<fs_arc_return>).

      me->protocol_collect(
        iv_object  = |{ <fs_arc_return>-arcid }\|{ <fs_arc_return>-guid }|
        iv_text    = <fs_arc_return>-message
        iv_msgtype = SWITCH #( <fs_arc_return>-type
          WHEN mc->msgtype_e OR mc->msgtype_a THEN mc->arc_log_msgtype_not_processed
          WHEN mc->msgtype_w THEN mc->arc_log_msgtype_others
          WHEN mc->msgtype_s OR mc->msgtype_i THEN mc->arc_log_msgtype_processed )
        iv_msgid   = <fs_arc_return>-id
        iv_msgno   = <fs_arc_return>-number
        iv_msgv1   = <fs_arc_return>-message_v1
        iv_msgv2   = <fs_arc_return>-message_v2
        iv_msgv3   = <fs_arc_return>-message_v3
        iv_msgv4   = <fs_arc_return>-message_v4 ).

    ENDLOOP.

  ENDMETHOD.


  METHOD /sct/qp_if_arc_type~close.

    me->close( ).

  ENDMETHOD.


  METHOD /sct/qp_if_arc_type~get_file_id.

    rv_arcfid = me->mv_file_key.

  ENDMETHOD.


  METHOD /sct/qp_if_arc_type~get_type.

    rv_arctype = mc->arctype_adk.

  ENDMETHOD.


  METHOD /sct/qp_if_arc_type~open.

    IF is_arcnode-arcid = mc->arcid_standard.
      mv_object = mc->arc_object_standard.
    ELSE.
      mv_object = mc->arc_object_versions.
    ENDIF.

    mv_arcid = is_arcnode-arcid.

    CASE iv_arc_action.

      WHEN mc->arc_action-write.

        me->open_for_write(
*         This parameter set TRUE results in archived files created as "snapshots".
*         As a result of that, it won't be possible to perform deletion of the archived data.
          iv_no_delete = COND #( WHEN is_arcnode-arcid <> mc->arcid_standard THEN abap_true )
          iv_test_mode = iv_test_mode ).

        me->protocol_init( iv_protocol_output ).

      WHEN mc->arc_action-read.

        me->open_for_read(
          iv_archive_document = is_arcnode-arcsid
          it_r_file_selection = VALUE #( ( sign = 'I' option = 'EQ' low = is_arcnode-arcfid ) ) ).

        me->protocol_init( iv_protocol_output ).  "MD190523 N2160 INS

      WHEN mc->arc_action-restore.

        IF is_arcnode-arcid = mc->arcid_standard.

          me->open_for_restore( iv_file_key = is_arcnode-arcfid iv_test_mode = iv_test_mode ).

        ELSE. " Version Archive

*         We do not use the standard ADK restore, so we open like we simply want to read...
          me->open_for_read(
            iv_archive_document = is_arcnode-arcsid
            it_r_file_selection = VALUE #( ( sign = 'I' option = 'EQ' low = is_arcnode-arcfid ) ) ).

        ENDIF.

        me->protocol_init( iv_protocol_output ).

        me->protocol_collect(
            iv_msgtype = mc->arc_log_msgtype_processed
            iv_msgno   = mc->msgno_327
            iv_msgv1   = is_arcnode-arcfid
            iv_msgv2   = mc->arc_action-restore ).

      WHEN mc->arc_action-delete.

        me->open_for_delete( iv_file_key = is_arcnode-arcfid iv_test_mode = abap_true ).

        me->protocol_init( iv_protocol_output ).

        me->protocol_collect(
            iv_msgtype = mc->arc_log_msgtype_processed
            iv_msgno   = mc->msgno_327
            iv_msgv1   = is_arcnode-arcfid
            iv_msgv2   = mc->arc_action-delete ).

      WHEN mc->arc_action-mark_for_deletion.

        me->protocol_init( iv_protocol_output ).

        me->protocol_collect(
            iv_msgtype = mc->arc_log_msgtype_processed
            iv_msgno   = mc->msgno_327
            iv_msgv1   = is_arcnode-arcfid
            iv_msgv2   = mc->arc_action-mark_for_deletion ).

    ENDCASE.

  ENDMETHOD.


  METHOD /sct/qp_if_arc_type~open_for_delete.

    CLEAR et_object_ids.

    me->open_for_delete( iv_test_mode = iv_test_mode ).

    DATA(lv_eof) = abap_false.
    WHILE lv_eof = abap_false.
      me->next_object( IMPORTING ev_end_of_files = lv_eof ).
      IF lv_eof = abap_false.
        INSERT mv_data_object INTO TABLE et_object_ids.
      ENDIF.
    ENDWHILE.

  ENDMETHOD.


  METHOD /sct/qp_if_arc_type~read.

    TRY.
        me->read_object(
          iv_object_id  = CONV #( is_arcnode-guid )
          iv_file_key   = is_arcnode-arcfid
          iv_offset     = is_arcnode-objoffset ).

*       Unlike on writing, we abort the reading process completely when an exception occures (no RESUME)
        me->get_node_data( IMPORTING es_db_data = es_db_data ).

        me->close_object( ).

      CATCH /sct/qp_cx_error INTO DATA(lx).
        lx->arcid = is_arcnode-arcid. " Add current ARCID
        RAISE EXCEPTION lx.
    ENDTRY.

  ENDMETHOD.


  METHOD /sct/qp_if_arc_type~read_customizing.

    me->map_init_data(
      EXPORTING
        iv_direction = me->data_map_direction_read
      IMPORTING
        es_cust_db      = es_cust_db ).

  ENDMETHOD.


  METHOD /sct/qp_if_arc_type~write.

    CLEAR es_arcnode.

    IF me->mv_handle IS INITIAL.
      RAISE EXCEPTION TYPE /sct/qp_cx_error
        EXPORTING
          textid     = /sct/qp_cx_error=>arc_not_open
          arc_action = mc->arc_action-write.
    ENDIF.

*   Create single data object for all QV related data
    me->new_object( is_root_select-guid ).

    TRY.
        me->put_node_data( is_qv_data = is_db_data ).

*     Single errors when archiving data will be automatically noted into the archiving session protocol
*     We want to continue the process here anyway, so return to the raising context using RESUME.
      CATCH BEFORE UNWIND /sct/qp_cx_error INTO DATA(lx).
        IF lx->is_resumable = abap_true.
          RESUME.
        ENDIF.
    ENDTRY.

*   Save data object here but do not close the session. This should be
*   done by SAVE after all WRITE calls for QVs to archived were performed.
    me->save_object( IMPORTING ev_offset = DATA(lv_object_offset) ).

    es_arcnode = VALUE /sct/qp_arcnode(
        arcid       = mv_arcid
        guid        = is_root_select-guid
        arcsid      = me->mv_document
        arcfid      = me->mv_file_key
        objoffset   = lv_object_offset
        arctype     = me->/sct/qp_if_arc_type~get_type( )
        arcformvers = mc_arcformvers ).

  ENDMETHOD.


  METHOD /sct/qp_if_arc_type~write_customizing.

    me->map_init_data(
        is_cust_db   = is_cust_db
        iv_direction = me->data_map_direction_write ).

    me->protocol_collect(
        iv_msgtype = mc->arc_log_msgtype_processed
        iv_msgno   = mc->msgno_326 ).

  ENDMETHOD.


  METHOD close.

    IF mv_protocol_output = mc->arc_protocol_output_list_bal
    OR mv_protocol_output = mc->arc_protocol_output_list.
      CALL FUNCTION 'ARCHIVE_WRITE_STATISTICS'
        EXPORTING
          archive_handle          = mv_handle    " Handle auf die geöffneten Archivdateien
*         statistics_only_per_run = SPACE    " Keine Statistik für einzelne Dateien ausgeben
*         statistics_only_per_file = SPACE    " Keine Statistik für gesamten Lauf ausgeben
        EXCEPTIONS
          internal_error          = 1
          wrong_access_to_archive = 2
          OTHERS                  = 3.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                   WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO DATA(lv_message).
        RAISE EXCEPTION TYPE /sct/qp_cx_error
          EXPORTING
            textid  = /sct/qp_cx_error=>arc_close
            message = lv_message.
      ENDIF.
    ENDIF.

    me->get_files_of_handle( IMPORTING et_archive_files = DATA(lt_files) ).

    LOOP AT lt_files ASSIGNING FIELD-SYMBOL(<fs_file>).
      me->protocol_collect(
          iv_msgtype = mc->arc_log_msgtype_processed
          iv_msgno   = mc->msgno_324
          iv_msgv1   = <fs_file>-archiv_key ).
    ENDLOOP.

    IF mv_protocol_output = mc->arc_protocol_output_list_bal
    OR mv_protocol_output = mc->arc_protocol_output_list.
      IF mv_protocol_handle IS NOT INITIAL.
        CALL FUNCTION 'ARCHIVE_PROTOCOL_WRITE'
          EXPORTING
            i_protocol_handle = mv_protocol_handle.    " Sonderfunktion: Handle auf ein Protokoll, falls mehr als ein
      ENDIF.
    ENDIF.

    CALL FUNCTION 'ARCHIVE_CLOSE_FILE'
      EXPORTING
        archive_handle               = mv_handle    " Handle auf geöffnete Archive
      EXCEPTIONS
        internal_error               = 1
        wrong_access_to_archive      = 2
        archiving_standard_violation = 3
        OTHERS                       = 4.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                 WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO lv_message.
      RAISE EXCEPTION TYPE /sct/qp_cx_error
        EXPORTING
          textid  = /sct/qp_cx_error=>arc_close
          message = lv_message.
    ENDIF.

    CLEAR mv_data_object.
    CLEAR mv_file_key.
    CLEAR mv_handle.
    CLEAR mv_protocol_handle.
    CLEAR mv_protocol_output.

  ENDMETHOD.


  METHOD close_object.

    IF mv_object_handle IS NOT INITIAL.

      CALL FUNCTION 'ARCHIVE_CLOSE_FILE'
        EXPORTING
          archive_handle               = mv_object_handle
        EXCEPTIONS
          internal_error               = 1
          wrong_access_to_archive      = 2
          archiving_standard_violation = 3
          OTHERS                       = 4.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                   WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO DATA(lv_message).
        RAISE EXCEPTION TYPE /sct/qp_cx_error
          EXPORTING
            textid  = /sct/qp_cx_error=>arc_close
            message = lv_message.
      ENDIF.

    ENDIF.

    CLEAR mv_object_handle.

  ENDMETHOD.


  METHOD constructor.

    /sct/qp_cl_factory=>get_instances( IMPORTING eo_const = mc ).

  ENDMETHOD.


  METHOD get_active_components.

    rs_active_components = VALUE #(
      object      = mv_object
      document    = mv_document
      file_key    = mv_file_key
      data_object = mv_data_object
    ).

  ENDMETHOD.


  METHOD get_active_sessions.

    CLEAR et_active_sessions.

    CALL FUNCTION 'ARCHIVE_GET_ACTIVE_SESSIONS'
      IMPORTING
        active_sessions = et_active_sessions.

  ENDMETHOD.


  METHOD get_files_of_handle.

    CALL FUNCTION 'ARCHIVE_GET_ARCHIVE_FILES'
      EXPORTING
        archive_handle          = mv_handle    " Handle auf geöffnete Archive
      TABLES
        archive_files           = et_archive_files    " Tabelle mit allen geöffneten Archivdateien
      EXCEPTIONS
        wrong_access_to_archive = 1
        internal_error          = 2
        OTHERS                  = 3.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                 WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO DATA(lv_message).
      RAISE EXCEPTION TYPE /sct/qp_cx_error
        EXPORTING
          textid  = /sct/qp_cx_error=>arc_adk
          message = lv_message.
    ENDIF.

  ENDMETHOD.


  METHOD get_files_of_session.

    CALL FUNCTION 'ARCHIVE_GET_FILES_OF_SESSION'
      EXPORTING
        session                = mv_document    " Identifikation eines Archivierungslaufs
      TABLES
        files_of_session       = et_archive_files     " Archivdatei: Schlüssel, Objektanzahl, phys. Name mit Pfad
      EXCEPTIONS
        session_does_not_exist = 1
        OTHERS                 = 2.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                 WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO DATA(lv_message).
      RAISE EXCEPTION TYPE /sct/qp_cx_error
        EXPORTING
          textid  = /sct/qp_cx_error=>arc_adk
          message = lv_message.
    ENDIF.

  ENDMETHOD.


  METHOD get_information.

    CALL FUNCTION 'ARCHIVE_GET_INFORMATION'
      EXPORTING
        archive_handle          = mv_handle    " Handle auf geöffnete Archive
      IMPORTING
        archive_creation_date   = ev_creation_date    " Datum, an dem das Archiv erzeugt wurde
*       archive_creation_release =     " Release, unter dem das Archiv erzeugt wurde
        archive_creation_system = ev_creation_system    " SAP-System, unter dem das Archiv erzeugt wurde
        archive_document        = ev_document    " Archivierungslauf laut Archivverwaltung
        archive_name            = ev_file_key    " Archiv-Schlüssel laut Archivverwaltung
*       object                  =     " Name des mit dem Handle bearbeiteten Objekts
        archive_code_page       = ev_code_page    " Bezeichnung der Codepage
        archive_number_format   = ev_number_format    " Bezeichnung des Nummernformats
        adk_version             = ev_adk_version
*       archiving_class         =     " Archivierungsklasse
*       object_number_in_file   =     " Anzahl der Objekte in einer Archivdatei
*       object_number_in_run    =     " Anzahl der Objekte in einem Archivierungslauf
*    TABLES
*       used_classes            =
      EXCEPTIONS
        internal_error          = 1
        wrong_access_to_archive = 2
        OTHERS                  = 3.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                 WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO DATA(lv_message).
      RAISE EXCEPTION TYPE /sct/qp_cx_error
        EXPORTING
          textid  = /sct/qp_cx_error=>arc_adk
          message = lv_message.
    ENDIF.

  ENDMETHOD.


  METHOD get_init_structures.

    CALL FUNCTION 'ARCHIVE_GET_INIT_STRUCTURES'
      EXPORTING
        archive_handle          = mv_handle    " Handle auf geöffnete Archivdateien
      TABLES
        record_structures       = et_init_structures    " Struktur oder Tabellentyp aus DDIC
      EXCEPTIONS
        wrong_access_to_archive = 1
        OTHERS                  = 2.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                 WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO DATA(lv_message).
      RAISE EXCEPTION TYPE /sct/qp_cx_error
        EXPORTING
          textid  = /sct/qp_cx_error=>arc_adk
          message = lv_message.
    ENDIF.

  ENDMETHOD.


  METHOD get_node_data.
*--------------------------------------------------------------------*
* Änderungslog
*--------------------------------------------------------------------*
* MD, 2020.06.23: N2479 Zusätzliche Tabellen archivieren
*--------------------------------------------------------------------*

    IF iv_object_offset IS INITIAL.

      me->get_table( EXPORTING iv_record_structure = '/SCT/QP_NODE'       IMPORTING et_table = es_db_data-node      ).
      me->get_table( EXPORTING iv_record_structure = '/SCT/QP_NODET'      IMPORTING et_table = es_db_data-nodet     ).
      me->get_table( EXPORTING iv_record_structure = '/SCT/QP_NODEREL'    IMPORTING et_table = es_db_data-noderel   ).
      me->get_table( EXPORTING iv_record_structure = '/SCT/QP_STATUS'     IMPORTING et_table = es_db_data-status    ).
      me->get_table( EXPORTING iv_record_structure = '/SCT/QP_STX'        IMPORTING et_table = es_db_data-stx       ).
      me->get_table( EXPORTING iv_record_structure = '/SCT/QP_VAL'        IMPORTING et_table = es_db_data-val       ).
      me->get_table( EXPORTING iv_record_structure = '/SCT/QP_VALT'       IMPORTING et_table = es_db_data-valt      ).
      me->get_table( EXPORTING iv_record_structure = '/SCT/QP_PMK'        IMPORTING et_table = es_db_data-pmk       ).
      me->get_table( EXPORTING iv_record_structure = '/SCT/QP_ANA'        IMPORTING et_table = es_db_data-ana       ).
      me->get_table( EXPORTING iv_record_structure = '/SCT/QP_BDS'        IMPORTING et_table = es_db_data-bds       ).
      me->get_table( EXPORTING iv_record_structure = '/SCT/QP_LOG'        IMPORTING et_table = es_db_data-log       ).
      me->get_table( EXPORTING iv_record_structure = '/SCT/QP_S_STXTEXT'  IMPORTING et_table = es_db_data-text      ).
      " MD, 2020.06.23: N2479, BoI
      me->get_table( EXPORTING iv_record_structure = '/SCT/QP_NUM'        IMPORTING et_table = es_db_data-num       ).
      me->get_table( EXPORTING iv_record_structure = 'CDHDR'              IMPORTING et_table = es_db_data-cdhdr     ).
      me->get_table( EXPORTING iv_record_structure = 'CDPOS'              IMPORTING et_table = es_db_data-cdpos     ).
      me->get_table( EXPORTING iv_record_structure = 'CDPOS_UID'          IMPORTING et_table = es_db_data-cdpos_uid ).
      " MD, 2020.06.23: N2479, EoI

    ELSE.

      DATA(lt_table_buffer) = VALUE as_t_tablebuffer( ).

      CALL FUNCTION 'ARCHIVE_READ_OBJECT_BY_OFFSET'
        EXPORTING
          iv_archivekey                = iv_file_key    " Schlüssel einer Archivdatei
          iv_offset                    = iv_object_offset    " Offset des Datenobjekts in der Archivdatei
*         iv_read_class_data           = 'CONTEXT'    " Lesen von mit Archivierungsklassen archivierten Daten
        CHANGING
          ct_obj_data                  = lt_table_buffer    " Tabellen zu einem Datenobjekt
        EXCEPTIONS
          end_of_object                = 1
          internal_error               = 2
          wrong_access_to_archive      = 3
          no_record_found              = 4
          file_io_error                = 5
          open_error                   = 6
          object_not_found             = 7
          not_authorized               = 8
          archiving_standard_violation = 9
          OTHERS                       = 10.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                   WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO DATA(lv_message).
        RAISE EXCEPTION TYPE /sct/qp_cx_error
          EXPORTING
            textid  = /sct/qp_cx_error=>arc_adk
            message = lv_message.
      ENDIF.

      FIELD-SYMBOLS <ft_table> TYPE STANDARD TABLE.
      ASSIGN lt_table_buffer[ tabname = '/SCT/QP_NODE'      ]-tabref TO FIELD-SYMBOL(<fr_table>).
      ASSIGN <fr_table>->* TO <ft_table>.
      es_db_data-node   = <ft_table>.
      ASSIGN lt_table_buffer[ tabname = '/SCT/QP_NODET'     ]-tabref TO <fr_table>.
      ASSIGN <fr_table>->* TO <ft_table>.
      es_db_data-nodet  = <ft_table>.
      ASSIGN lt_table_buffer[ tabname = '/SCT/QP_NODEREL'   ]-tabref TO <fr_table>.
      ASSIGN <fr_table>->* TO <ft_table>.
      es_db_data-noderel = <ft_table>.
      ASSIGN lt_table_buffer[ tabname = '/SCT/QP_STATUS'    ]-tabref TO <fr_table>.
      ASSIGN <fr_table>->* TO <ft_table>.
      es_db_data-status = <ft_table>.
      ASSIGN lt_table_buffer[ tabname = '/SCT/QP_STX'       ]-tabref TO <fr_table>.
      ASSIGN <fr_table>->* TO <ft_table>..
      es_db_data-stx    = <ft_table>.
      ASSIGN lt_table_buffer[ tabname = '/SCT/QP_VAL'       ]-tabref TO <fr_table>.
      ASSIGN <fr_table>->* TO <ft_table>.
      es_db_data-val    = <ft_table>.
      ASSIGN lt_table_buffer[ tabname = '/SCT/QP_VALT'      ]-tabref TO <fr_table>.
      ASSIGN <fr_table>->* TO <ft_table>.
      es_db_data-valt   = <ft_table>.
      ASSIGN lt_table_buffer[ tabname = '/SCT/QP_PMK'       ]-tabref TO <fr_table>.
      ASSIGN <fr_table>->* TO <ft_table>.
      es_db_data-pmk    = <ft_table>.
      ASSIGN lt_table_buffer[ tabname = '/SCT/QP_ANA'       ]-tabref TO <fr_table>.
      ASSIGN <fr_table>->* TO <ft_table>.
      es_db_data-ana    = <ft_table>.
      ASSIGN lt_table_buffer[ tabname = '/SCT/QP_BDS'       ]-tabref TO <fr_table>.
      ASSIGN <fr_table>->* TO <ft_table>.
      es_db_data-bds    = <ft_table>.
      ASSIGN lt_table_buffer[ tabname = '/SCT/QP_LOG'       ]-tabref TO <fr_table>.
      ASSIGN <fr_table>->* TO <ft_table>.
      es_db_data-log    = <ft_table>.
      ASSIGN lt_table_buffer[ tabname = '/SCT/QP_S_STXTEXT' ]-tabref TO <fr_table>.
      ASSIGN <fr_table>->* TO <ft_table>.
      es_db_data-text   = <ft_table>.
      " MD, 2020.06.23: N2479, BoI
      ASSIGN lt_table_buffer[ tabname = '/SCT/QP_NUM'       ]-tabref TO <fr_table>.
      ASSIGN <fr_table>->* TO <ft_table>.
      es_db_data-num        = <ft_table>.
      ASSIGN lt_table_buffer[ tabname = 'CDHDR'             ]-tabref TO <fr_table>.
      ASSIGN <fr_table>->* TO <ft_table>.
      es_db_data-cdhdr      = <ft_table>.
      ASSIGN lt_table_buffer[ tabname = 'CDPOS'             ]-tabref TO <fr_table>.
      ASSIGN <fr_table>->* TO <ft_table>.
      es_db_data-cdpos      = <ft_table>.
      ASSIGN lt_table_buffer[ tabname = 'CDPOS_UID'         ]-tabref TO <fr_table>.
      ASSIGN <fr_table>->* TO <ft_table>.
      es_db_data-cdpos_uid  = <ft_table>.
      " MD, 2020.06.23: N2479, EoI

    ENDIF.

  ENDMETHOD.


  METHOD get_table.

    CLEAR et_table.

    CALL FUNCTION 'ARCHIVE_GET_TABLE'
      EXPORTING
        archive_handle          = COND #( WHEN mv_object_handle IS NOT INITIAL THEN mv_object_handle ELSE mv_handle )
        record_structure        = iv_record_structure    " Name der Struktur aller Datensätze der Tabelle
        all_records_of_object   = abap_true    " alle Records der Struktur im Datenobjekt lesen
*       automatic_conversion    = 'X'    " automatische Umsetzung aller Datensätze
*       archiving_class         = SPACE    " Archivierungsklasse
*      IMPORTING
*       record_cursor           =     " Zeiger auf einen Datensatz im Datenobjekt
*       record_flags            =     " Flagleiste für alle Datensätze der Tabelle
*       record_length           =     " Länge der Datensätze der Tabelle
      TABLES
        table                   = et_table    " Tabelle, die die Datensätze enthält
*       record_flags_table      =     " Flagleiste für alle Datensätze der Tabelle
      EXCEPTIONS
        end_of_object           = 1
        internal_error          = 2
        wrong_access_to_archive = 3
        OTHERS                  = 4.
    IF sy-subrc <> 0.
      me->protocol_collect(
          iv_object  = mv_data_object
          iv_msgno   = mc->msgno_319
          iv_msgv1   = mc->arc_action-read
          iv_msgv2   = space
          iv_msgv3   = iv_record_structure
          iv_msgtype = mc->arc_log_msgtype_not_processed ).
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                 WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO DATA(lv_message).
      RAISE RESUMABLE EXCEPTION TYPE /sct/qp_cx_error
        EXPORTING
          textid  = /sct/qp_cx_error=>arc_adk
          message = lv_message.
    ENDIF.

    me->protocol_collect(
        iv_object  = mv_data_object
        iv_msgno   = mc->msgno_320
        iv_msgv1   = mc->arc_action-read
        iv_msgv2   = lines( et_table )
        iv_msgv3   = iv_record_structure
        iv_msgtype = mc->arc_log_msgtype_processed ).

  ENDMETHOD.


  METHOD is_session_active.

    me->get_active_sessions( IMPORTING et_active_sessions = DATA(lt_active_sessions)  ).

    IF lt_active_sessions IS NOT INITIAL.
      rv_active = abap_true.
    ENDIF.

  ENDMETHOD.


  METHOD map_init_data.

*    get_init_structures( IMPORTING et_init_structures = DATA(lt_init_structures) ).

    DATA(lo_cust_descr) = CAST cl_abap_structdescr( cl_abap_typedescr=>describe_by_data( es_cust_db ) ).
    LOOP AT lo_cust_descr->components ASSIGNING FIELD-SYMBOL(<fs_component>) WHERE name <> 'ARCSID'.

      DATA(lo_cust_table_descr)     = CAST cl_abap_tabledescr( lo_cust_descr->get_component_type( <fs_component>-name ) ).
      DATA(lo_cust_line_type_descr) = CAST cl_abap_structdescr( lo_cust_table_descr->get_table_line_type( ) ).
      DATA(lv_cust_line_type_name)  = CONV tabname( lo_cust_line_type_descr->get_relative_name( ) ).

      DATA(lr_cust_table_buffer) = REF data( space ).
      CREATE DATA lr_cust_table_buffer TYPE STANDARD TABLE OF (lv_cust_line_type_name).
      FIELD-SYMBOLS <ft_cust_table_buffer> TYPE STANDARD TABLE.
      ASSIGN lr_cust_table_buffer->* TO <ft_cust_table_buffer>.

      IF iv_direction = data_map_direction_read.

        ASSIGN COMPONENT <fs_component>-name OF STRUCTURE es_cust_db TO FIELD-SYMBOL(<ft_cust_table>).

        CALL FUNCTION 'ARCHIVE_GET_INIT_DATA'
          EXPORTING
            archive_handle          = mv_handle    " Handle auf geöffnete Archivdateien
            record_structure        = lv_cust_line_type_name    " Name der Struktur aller Datensätze der Tabelle
          TABLES
            init_data               = <ft_cust_table_buffer>    " Tabelle mit Initialisierungsdaten
          EXCEPTIONS
            wrong_access_to_archive = 1
            OTHERS                  = 2.
        DATA(lv_subrc) = sy-subrc.

        <ft_cust_table> = <ft_cust_table_buffer>.

      ELSEIF iv_direction = data_map_direction_write.

        ASSIGN COMPONENT <fs_component>-name OF STRUCTURE is_cust_db TO <ft_cust_table>.

        <ft_cust_table_buffer> = <ft_cust_table>.

        CALL FUNCTION 'ARCHIVE_PUT_INIT_DATA'
          EXPORTING
            archive_handle          = mv_handle    " Handle auf geöffnete Archive
            record_structure        = lv_cust_line_type_name    " Name der Struktur aller Datensätze der Tabelle
          TABLES
            init_data               = <ft_cust_table_buffer>    " Tabelle mit Initialisierungsdaten
          EXCEPTIONS
            wrong_access_to_archive = 1
            called_too_late         = 2
            OTHERS                  = 3.
        lv_subrc = sy-subrc.

      ENDIF.

      IF lv_subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                   WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO DATA(lv_message).
        RAISE RESUMABLE EXCEPTION TYPE /sct/qp_cx_error
          EXPORTING
            textid  = /sct/qp_cx_error=>arc_adk
            message = lv_message.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.


  METHOD new_object.

    CALL FUNCTION 'ARCHIVE_NEW_OBJECT'
      EXPORTING
        archive_handle          = mv_handle    " Handle auf das geöffnete Archiv
        object_id               = iv_guid    " Identifikation des neuen Datenobjekts
      EXCEPTIONS
        internal_error          = 1
        wrong_access_to_archive = 2
        OTHERS                  = 3.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                 WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO DATA(lv_message).
      RAISE EXCEPTION TYPE /sct/qp_cx_error
        EXPORTING
          textid  = /sct/qp_cx_error=>arc_adk
          message = lv_message.
    ENDIF.

    mv_data_object = iv_guid.

  ENDMETHOD.


  METHOD next_object.

    CLEAR ev_end_of_files.

    CALL FUNCTION 'ARCHIVE_GET_NEXT_OBJECT'
      EXPORTING
        archive_handle          = mv_handle    " Handle auf das geöffnete Archiv
      IMPORTING
        object_id               = mv_data_object    " Identifikation des gelesenen Datenobjekts
*       object_offset           =     " Offset des Datenobjektes im Archiv
        archive_name            = mv_file_key    " Archiv-Schlüssel laut Archivverwaltung
*       compr_object_length     =     " Länge des Datenobjekts (komprimiert)
        session                 = mv_document    " Identifikation eines Archivierungslaufs
      EXCEPTIONS
        end_of_file             = 1
        file_io_error           = 2
        internal_error          = 3
        open_error              = 4
        wrong_access_to_archive = 5
        OTHERS                  = 6.
    IF sy-subrc <> 0.
      IF sy-subrc = 1.
        ev_end_of_files = abap_true.
      ELSE.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                   WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO DATA(lv_message).
        RAISE EXCEPTION TYPE /sct/qp_cx_error
          EXPORTING
            textid  = /sct/qp_cx_error=>arc_adk
            message = lv_message.
      ENDIF.
    ENDIF.

  ENDMETHOD.


  METHOD open_for_delete.

    mv_object = mc->arc_object_standard.

    mv_arcid = mc->arcid_standard.

    CALL FUNCTION 'ARCHIVE_OPEN_FOR_DELETE'
      EXPORTING
        archive_name                 = iv_file_key    " Name der Archivdatei laut Archivverwaltung
        object                       = mv_object    " Name des Archivierungsobjekts
        test_mode                    = iv_test_mode    " Schalter für Testbetrieb
*       aindflag                     = 'X'
        no_statistics                = abap_true    " Schalter für Statistiken
*       output_sel_screen_when_dialog = SPACE    " Selektionsbild ausgeben, wenn im Dialogmodus
*       output_sel_screen_when_batch = SPACE    " Selektionsbild ausgeben, wenn im Hintergrund
      IMPORTING
        archive_handle               = mv_handle    " Handle auf die geöffneten Dateien
*      TABLES
*       selected_files               =     " Tabelle mit den selektierten Einträgen
      EXCEPTIONS
        file_already_open            = 1
        file_io_error                = 2
        internal_error               = 3
        no_files_available           = 4
        object_not_found             = 5
        open_error                   = 6
        not_authorized               = 7
        archiving_standard_violation = 8
        OTHERS                       = 9.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                 WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO DATA(lv_message).
      RAISE EXCEPTION TYPE /sct/qp_cx_error
        EXPORTING
          textid     = /sct/qp_cx_error=>arc_open
          arc_action = mc->arc_action-delete
          message    = lv_message.
    ENDIF.

  ENDMETHOD.


  METHOD open_for_read.

    CALL FUNCTION 'ARCHIVE_OPEN_FOR_READ'
      EXPORTING
        archive_document             = iv_archive_document    " Name des Archivierungslauf laut Archivverwaltung
*       archive_name                 = SPACE    " Name der Archivdatei laut Archivverwaltung
        object                       = mv_object    " Name des Archivierungsobjektes
*       maintain_index               = SPACE    " Flag zum Indexaufbau
      IMPORTING
        archive_handle               = mv_handle    " Handle auf die geöffneten Dateien
      TABLES
        archive_files                = it_r_file_selection    " Tabelle der gewünschten Archivdateien
        selected_files               = mt_selected_files    " Tabelle mit den selektierten Einträgen
      EXCEPTIONS
        file_already_open            = 1
        file_io_error                = 2
        internal_error               = 3
        no_files_available           = 4
        object_not_found             = 5
        open_error                   = 6
        not_authorized               = 7
        archiving_standard_violation = 8
        OTHERS                       = 9.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                 WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO DATA(lv_message).
      RAISE EXCEPTION TYPE /sct/qp_cx_error
        EXPORTING
          textid     = /sct/qp_cx_error=>arc_open
          arc_action = mc->arc_action-read
          message    = lv_message.
    ENDIF.

    mv_document = iv_archive_document.

  ENDMETHOD.


  METHOD open_for_restore.

    me->is_session_active( ).

*   File key will only be possible to pass to the followup function if the function
*   group ARCH is running in unit test mode, so we make a dirty assign here to enable it
    ASSIGN ('(SAPLARCH)GV_UNITTEST_MODE') TO FIELD-SYMBOL(<fv_unittest_mode>).
    <fv_unittest_mode> = abap_true.

*   To be able to restore an archive file, it must be in status deleted. As we want to be able
*   to restore even files not deleted from database (version archiving), we set the status manually now!
    DATA(lt_files) = VALUE t_file_key( ( archiv_key = iv_file_key ) ).
    CALL FUNCTION 'ARCHIVE_ADMIN_SET_STATUS'
      EXPORTING
*       files_are_converted  = 'X'    " Status setzen, daß die Dateien umgesetzt wurden
        files_are_deleted    = 'X'    " Status setzen, daß die Dateien gelöscht wurden
*       index_created        = ' '    " Index auf arch. Datenobjekte wurde aufgebaut
*       index_deleted        = ' '    " Index auf arch. Datenobjekte wurde abgebaut
      TABLES
        archive_files        = lt_files    " Tabelle mit den Namen der Archivdateien
      EXCEPTIONS
        cannot_change_status = 1
        OTHERS               = 2.
    IF sy-subrc <> 0 AND sy-subrc <> 1.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                 WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO DATA(lv_message1).
      RAISE EXCEPTION TYPE /sct/qp_cx_error
        EXPORTING
          textid  = /sct/qp_cx_error=>arc_adk
          message = lv_message1.
    ENDIF.

*   When unit test mode not active, a popup will appear to ask for a session to restore data from.
    CALL FUNCTION 'ARCHIVE_OPEN_FOR_MOVE'
      EXPORTING
        object                       = mv_object    " Name des Archivierungsobjekts
        test_mode                    = iv_test_mode    " Rückladeprogramm läuft als Testlauf
        archive_name                 = iv_file_key
      IMPORTING
        archive_read_handle          = mv_handle    " Handle auf die geöffneten Dateien zum Lesen
*       archive_write_handle         =     " Handle auf die geöffneten Dateien zum Schreiben
      EXCEPTIONS
        file_already_open            = 1
        file_io_error                = 2
        internal_error               = 3
        no_files_available           = 4
        object_not_found             = 5
        open_error                   = 6
        not_authorized               = 7
        archiving_standard_violation = 8
        OTHERS                       = 9.
    IF sy-subrc <> 0 AND sy-subrc <> 1.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                 WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO DATA(lv_message).
      RAISE EXCEPTION TYPE /sct/qp_cx_error
        EXPORTING
          textid     = /sct/qp_cx_error=>arc_open
          arc_action = mc->arc_action-restore
          message    = lv_message.
    ENDIF.

    <fv_unittest_mode> = abap_false.

  ENDMETHOD.


  METHOD open_for_write.

    CALL FUNCTION 'ARCHIVE_OPEN_FOR_WRITE'
      EXPORTING
        call_delete_job_in_test_mode = iv_test_mode    " Löschprogramm nur als Testlauf starten
        create_archive_file          = COND #( WHEN iv_test_mode = abap_false THEN abap_true )    " Archivdatei erzeugen oder nicht erzeugen
        object                       = mv_object
*       comments                     = SPACE    " Kommentarzeile für Archivierungslauf
        do_not_delete_data           = iv_no_delete    " Archivierte Daten nicht löschen
*       output_sel_screen_when_dialog = SPACE    " Selektionsbild ausgeben, wenn im Dialogmodus
*       output_sel_screen_when_batch = SPACE    " Selektionsbild ausgeben, wenn im Hintergrund
*       destroy                      = ABAP_FALSE    " Kennzeichen für Archivierungslauf zur Datenvernichtung
      IMPORTING
        archive_handle               = mv_handle
      EXCEPTIONS
        internal_error               = 1
        object_not_found             = 2
        open_error                   = 3
        not_authorized               = 4
        archiving_standard_violation = 5
        OTHERS                       = 6.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                 WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO DATA(lv_message).
      RAISE EXCEPTION TYPE /sct/qp_cx_error
        EXPORTING
          textid     = /sct/qp_cx_error=>arc_open
          arc_action = mc->arc_action-write
          message    = lv_message.
    ENDIF.

    me->get_information(
      IMPORTING
        ev_document = mv_document
        ev_file_key = mv_file_key ).

  ENDMETHOD.


  METHOD protocol_collect.

    DATA(lv_msgid) = COND #( WHEN iv_msgno IS NOT INITIAL THEN iv_msgid ELSE space ).

    CALL FUNCTION 'ARCHIVE_PROTOCOL_COLLECT'
      EXPORTING
        i_object                     = iv_object                " Objekt (Beleg, Auftrag etc.), zu dem eine Nachricht übergebe
        i_text                       = iv_text                  " Nachrichtentext (Wenn I_MSGID und I_MSGNO nicht verwendet we
        i_msgtype                    = iv_msgtype               " Nachrichtenart (1=bearbeitet, 2= nicht bearbeitet, 3= sonsti
        i_msgid                      = lv_msgid                 " Nachrichtenklasse (Wenn I_TEXT nicht verwendet wird)
        i_msgno                      = iv_msgno                 " Nachrichtennummer (Wenn I_TEXT nicht verwendet wird)
        i_msgv1                      = iv_msgv1                 " Nachrichtenvariable
        i_msgv2                      = iv_msgv2                 " Nachrichtenvariable
        i_msgv3                      = iv_msgv3                 " Nachrichtenvariable
        i_msgv4                      = iv_msgv4                 " Nachrichtenvariable
*       i_callback_parameter         = iv_callback_parameter    " Call Back Parameter für Objektdetails
*       i_protocol_data              = iv_protocol_data         " Sonderfunktion: Übergabe von Protokolldaten (z.B. aus aRFC K
        i_protocol_handle            = mv_protocol_handle       " Sonderfunktion: Handle auf ein Protokoll, falls mehr als ein
      EXCEPTIONS
        protocol_not_yet_initialized = 1
        OTHERS                       = 2.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                 WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO DATA(lv_message).
*     Protocol messages written without initialized protocol will be ignored.
*     This is mostly okay (e.g. when reading data), but for safety we provide a checkpoint here.
      ASSERT ID /sct/qp_arc_minor SUBKEY lv_message CONDITION sy-subrc = 0.
    ENDIF.

  ENDMETHOD.


  METHOD protocol_init.

    CALL FUNCTION 'ARCHIVE_PROTOCOL_INIT'
      EXPORTING
        i_detailprotocol  = arc_log_detail_complete    " Steuerung der Fortschreibung des Protokolls
        i_protocol_output = iv_output    " Steuerung der Ausgabe des Protokolls
*       i_callback_parameter     =     " Call Back Parameter für Objektdetails
*       i_context         =     " Informationen über den Kontext, aus dem der Baustein gerufen
*       i_father_protocol_handle =     " Sonderfunktion: Archivierung: Application Log - Handle des V
      IMPORTING
        e_protocol_handle = mv_protocol_handle.    " Sonderfunktion: Handle auf das erzeugte Protokoll

    mv_protocol_output = iv_output.

  ENDMETHOD.


  METHOD put_node_data.
*--------------------------------------------------------------------*
* Änderungslog
*--------------------------------------------------------------------*
* MD, 2020.06.23: N2479 Zusätzliche Tabellen archivieren
*--------------------------------------------------------------------*

    me->put_table( it_table = is_qv_data-node      iv_record_structure = '/SCT/QP_NODE' ).
    me->put_table( it_table = is_qv_data-nodet     iv_record_structure = '/SCT/QP_NODET' ).
    me->put_table( it_table = is_qv_data-noderel   iv_record_structure = '/SCT/QP_NODEREL' ).
    me->put_table( it_table = is_qv_data-status    iv_record_structure = '/SCT/QP_STATUS' ).
    me->put_table( it_table = is_qv_data-stx       iv_record_structure = '/SCT/QP_STX' ).
    me->put_table( it_table = is_qv_data-val       iv_record_structure = '/SCT/QP_VAL' ).
    me->put_table( it_table = is_qv_data-valt      iv_record_structure = '/SCT/QP_VALT' ).
    me->put_table( it_table = is_qv_data-pmk       iv_record_structure = '/SCT/QP_PMK' ).
    me->put_table( it_table = is_qv_data-ana       iv_record_structure = '/SCT/QP_ANA' ).
    me->put_table( it_table = is_qv_data-bds       iv_record_structure = '/SCT/QP_BDS' ).
    me->put_table( it_table = is_qv_data-log       iv_record_structure = '/SCT/QP_LOG' ).
    me->put_table( it_table = is_qv_data-text      iv_record_structure = '/SCT/QP_S_STXTEXT' ).
    " MD, 2020.06.23: N2479, BoI
    me->put_table( it_table = is_qv_data-num       iv_record_structure = '/SCT/QP_NUM' ).
    me->put_table( it_table = is_qv_data-cdhdr     iv_record_structure = 'CDHDR' ).
    me->put_table( it_table = is_qv_data-cdpos     iv_record_structure = 'CDPOS' ).
    me->put_table( it_table = is_qv_data-cdpos_uid iv_record_structure = 'CDPOS_UID' ).
    " MD, 2020.06.23: N2479, EoI

  ENDMETHOD.


  METHOD put_table.

    TRY.
        CALL FUNCTION 'ARCHIVE_PUT_TABLE'
          EXPORTING
            archive_handle           = mv_handle    " Handle auf die geöffneten Archivdateien
*           record_flags             = SPACE    " Flagleiste für alle Datensätze
            record_structure         = iv_record_structure    " Name der zu schreibenden Struktur
          TABLES
            table                    = it_table    " interne Tabelle für Datenobjekt
*           record_flags_table       =     " Flagleiste für alle Datensätze der Tabelle
          EXCEPTIONS
            internal_error           = 1
            wrong_access_to_archive  = 2
            invalid_record_structure = 3
            OTHERS                   = 4.
        IF sy-subrc <> 0.
          me->protocol_collect(
              iv_object  = mv_data_object
              iv_msgno   = mc->msgno_319
              iv_msgv1   = mc->arc_action-write
              iv_msgv2   = lines( it_table )
              iv_msgv3   = iv_record_structure
              iv_msgtype = mc->arc_log_msgtype_not_processed ).
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                     WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO DATA(lv_message).
          RAISE RESUMABLE EXCEPTION TYPE /sct/qp_cx_error
            EXPORTING
              textid  = /sct/qp_cx_error=>arc_adk
              message = lv_message.
        ENDIF.

        me->protocol_collect(
            iv_object  = mv_data_object
            iv_msgno   = mc->msgno_320
            iv_msgv1   = mc->arc_action-write
            iv_msgv2   = lines( it_table )
            iv_msgv3   = iv_record_structure
            iv_msgtype = mc->arc_log_msgtype_processed ).

*     When an exception occurs and the caller does not resume execution in the higher level catch block,
*     an additional message will be thrown stating the process abortion before returning to the caller
      CLEANUP.
        me->protocol_collect(
            iv_object  = mv_data_object
            iv_msgno   = mc->msgno_321
            iv_msgv1   = mc->arc_action-write
            iv_msgtype = mc->arc_log_msgtype_not_processed ).
    ENDTRY.

  ENDMETHOD.


  METHOD read_file.

    CLEAR mv_data_object.

    DATA(lv_found_file)   = abap_false.
    DATA(lv_end_of_files) = abap_false.
    WHILE lv_end_of_files = abap_false AND lv_found_file = abap_false.

      me->next_object( IMPORTING ev_end_of_files = lv_end_of_files ).

      IF mv_file_key = iv_file_key.
        lv_found_file = abap_true.
      ENDIF.

    ENDWHILE.

    IF lv_found_file = abap_false.
      RAISE EXCEPTION TYPE /sct/qp_cx_error.
*        EXPORTING
*          textid = /sct/qp_cx_error=>arc_file_not_found
*          arcfid = mv_file_key.
    ENDIF.

  ENDMETHOD.


  METHOD read_object.

    CLEAR: mv_data_object, mv_object_handle.

    DATA(lv_found_object) = abap_false.

    IF iv_offset IS NOT INITIAL.

*     The following function call is not working with OBJECT_ID because we need a connection to an index table
*     where the object-file-dataobject relations are stored. It is not clear where to configure
*     that index table. BUT we can use the offset if given!
      CALL FUNCTION 'ARCHIVE_READ_OBJECT'
        EXPORTING
          object                    = mv_object    " Name des Archivierungsobjektes
*         object_id                 = iv_object_id    " Schlüssel des Datenobjektes
*         user_exit_program         = SPACE    " Userexit, Name des Programms
*         user_exit_form            = SPACE    " Userexit, Name der Formroutine
          archivkey                 = iv_file_key    " logische Name der Archivdatei
          offset                    = iv_offset    " Adresse des Datenobjektes
*         moveflag                  = SPACE    " Steuerflag zum Rückladen
        IMPORTING
          archive_handle            = mv_object_handle    " Zeiger auf geöffnete Datei
*         compr_object_length       =     " Länge des Datenobjekts (komprimiert)
        EXCEPTIONS
          no_record_found           = 1
          file_io_error             = 2
          internal_error            = 3
          open_error                = 4
          cancelled_by_user         = 5
          archivelink_error         = 6
          object_not_found          = 7
          filename_creation_failure = 8
          file_already_open         = 9
          not_authorized            = 10
          file_not_found            = 11
          OTHERS                    = 12.
      IF sy-subrc <> 0.
        IF sy-subrc = 1.
          lv_found_object = abap_false.
        ELSE.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                     WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO DATA(lv_message).
          RAISE EXCEPTION TYPE /sct/qp_cx_error
            EXPORTING
              textid  = /sct/qp_cx_error=>arc_adk
              message = lv_message.
        ENDIF.
      ELSE.
        mv_data_object  = iv_object_id.
        lv_found_object = abap_true.
      ENDIF.

    ELSE.

      DATA(lv_end_of_files) = abap_false.
      WHILE lv_end_of_files = abap_false AND lv_found_object = abap_false.

        me->next_object( IMPORTING ev_end_of_files = lv_end_of_files ).

        IF mv_data_object = iv_object_id.
          lv_found_object = abap_true.
        ENDIF.

      ENDWHILE.

    ENDIF.

    IF lv_found_object = abap_false.
      RAISE EXCEPTION TYPE /sct/qp_cx_error
        EXPORTING
          textid        = /sct/qp_cx_error=>arc_object_not_found
          arc_object_id = iv_object_id
          arcfid        = iv_file_key.
    ENDIF.

  ENDMETHOD.


  METHOD save_object.

    DATA(lv_file_key_prev) = mv_file_key.

    CALL FUNCTION 'ARCHIVE_SAVE_OBJECT'
      EXPORTING
        archive_handle          = mv_handle    " Handle auf die geöffnete Archivdatei
      IMPORTING
        object_offset           = ev_offset
        archive_name            = mv_file_key
*       end_of_retention        =     " ILM: Endedatum des minimalen Aufbewahrungszeitraums
      EXCEPTIONS
        file_io_error           = 1
        internal_error          = 2
        open_error              = 3
        termination_requested   = 4
        wrong_access_to_archive = 5
        data_object_not_saved   = 6
        OTHERS                  = 7.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                 WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO DATA(lv_message).
      RAISE EXCEPTION TYPE /sct/qp_cx_error
        EXPORTING
          textid  = /sct/qp_cx_error=>arc_adk
          message = lv_message.
    ENDIF.

    IF mv_file_key <> lv_file_key_prev.
      me->protocol_collect(
          iv_msgtype = mc->arc_log_msgtype_processed
          iv_msgno   = mc->msgno_325
          iv_msgv1   = mv_file_key ).
    ENDIF.

  ENDMETHOD.
ENDCLASS.
