CLASS /sct/qp_cl_arc_rfc DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    "! Archiving format version. Indicates the state of DDIC structures the archiving is performed with.
    "! This version number is saved along with ARCNODE entries on creation. If data is to be restored on
    "! a system, the value of this constant can be compared with the version of ARCNODE entries to
    "! restore to be warned about possible incompatibilities to the installed QPPD DDIC formats.
    CONSTANTS mc_arcformvers TYPE /sct/qp_arc_format_version VALUE '1.0'.

    METHODS constructor RAISING /sct/qp_cx_error.

    INTERFACES /sct/qp_if_arc_type.

*    METHODS /sct/qp_if_arc_type~get_type REDEFINITION.
*    METHODS /sct/qp_if_arc_type~open REDEFINITION.
*    METHODS /sct/qp_if_arc_type~read REDEFINITION.
*    METHODS /sct/qp_if_arc_type~write REDEFINITION.
*    METHODS /sct/qp_if_arc_type~write_customizing REDEFINITION.
*    METHODS /sct/qp_if_arc_type~read_customizing REDEFINITION.
*    METHODS /sct/qp_if_arc_type~close REDEFINITION.
*    METHODS /sct/qp_if_arc_type~get_file_id REDEFINITION.
*    METHODS /sct/qp_if_arc_type~open_for_delete REDEFINITION.

  PROTECTED SECTION.

    CLASS-DATA mc TYPE REF TO /sct/qp_cl_const.

    DATA mv_arcid TYPE /sct/qp_arcid.

    DATA ms_arc      TYPE /sct/qp_arc.
    DATA mt_arcnode  TYPE /sct/qp_t_arcnode.
    DATA mt_arcnodet TYPE /sct/qp_t_arcnodet.

  PRIVATE SECTION.
    DATA mv_test_mode TYPE abap_bool.

ENDCLASS.



CLASS /SCT/QP_CL_ARC_RFC IMPLEMENTATION.


  METHOD /sct/qp_if_arc_type~add_message.                   "#EC NEEDED

  ENDMETHOD.


  METHOD /sct/qp_if_arc_type~close.

    mv_test_mode = abap_false.

  ENDMETHOD.


  METHOD /sct/qp_if_arc_type~get_file_id.                   "#EC NEEDED

  ENDMETHOD.


  METHOD /sct/qp_if_arc_type~get_type.

    rv_arctype = mc->arctype_rfc.

  ENDMETHOD.


  METHOD /sct/qp_if_arc_type~open.

    mv_arcid = is_arcnode-arcid.
    mv_test_mode = iv_test_mode.

    SELECT SINGLE * FROM /sct/qp_arc INTO ms_arc WHERE arcid = is_arcnode-arcid.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE /sct/qp_cx_error
        EXPORTING
          textid = /sct/qp_cx_error=>arc_arcid_not_found.
    ENDIF.

  ENDMETHOD.


  METHOD /sct/qp_if_arc_type~open_for_delete.               "#EC NEEDED

  ENDMETHOD.


  METHOD /sct/qp_if_arc_type~read.

    DATA(lt_qvc_data) = VALUE /sct/qp_ts_qvc_data( ).
    DATA lv_msg TYPE text255.

    CALL FUNCTION '/SCT/QP_ARC_RFC_READ' DESTINATION ms_arc-rfcdest
      EXPORTING
        is_root_select        = CORRESPONDING /sct/qp_s_data_select( is_arcnode )
      IMPORTING
        es_db_data            = es_db_data
        et_qvc_data           = lt_qvc_data
      EXCEPTIONS "#EC FB_RC
        communication_failure = 1 MESSAGE lv_msg
        system_failure        = 2 MESSAGE lv_msg.

    et_qvc_data = CONV #( lt_qvc_data ).

  ENDMETHOD.


  METHOD /sct/qp_if_arc_type~read_customizing.              "#EC NEEDED

  ENDMETHOD.


  METHOD /sct/qp_if_arc_type~write.
*--------------------------------------------------------------------*
* Änderungslog
*--------------------------------------------------------------------*
* MD, 2021.01.08: N3027 Parameter it_qvc_data entfernt
*--------------------------------------------------------------------*
* AD, 2024.07.10, NOTE-3548
* COMMIT nicht steuerbar
*--------------------------------------------------------------------*

    DATA lv_msg TYPE text255.

    CALL FUNCTION '/SCT/QP_ARC_RFC_WRITE'
      DESTINATION ms_arc-rfcdest
      EXPORTING
        is_root_select        = is_root_select
        is_db_data            = is_db_data
        iv_test_mode          = mv_test_mode
        iv_commit_work        = iv_commit_work
      EXCEPTIONS "#EC FB_RC
        communication_failure = 1 MESSAGE lv_msg
        system_failure        = 2 MESSAGE lv_msg.

    es_arcnode = VALUE /sct/qp_arcnode(
        arcid       = mv_arcid
        guid        = is_root_select-guid
        arctype     = me->/sct/qp_if_arc_type~get_type( )
        arcformvers = mc_arcformvers ).

  ENDMETHOD.


  METHOD /sct/qp_if_arc_type~write_customizing. "#EC NEEDED

  ENDMETHOD.


  METHOD constructor.

    /sct/qp_cl_factory=>get_instances( IMPORTING eo_const = mc ).

  ENDMETHOD.
ENDCLASS.
