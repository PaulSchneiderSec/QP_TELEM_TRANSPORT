FUNCTION /sct/qp_arc_rfc_read.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     VALUE(IS_ROOT_SELECT) TYPE  /SCT/QP_S_DATA_SELECT
*"  EXPORTING
*"     VALUE(ES_DB_DATA) TYPE  /SCT/QP_S_DB_DATA
*"     VALUE(ET_QVC_DATA) TYPE  /SCT/QP_TS_QVC_DATA
*"     VALUE(ET_ARCNODE) TYPE  /SCT/QP_T_ARCNODE
*"----------------------------------------------------------------------

*--------------------------------------------------------------------*
* Änderungslog
*--------------------------------------------------------------------*
* AD, 2020.01.07, NOTE 3027
* Variablen aus TOP-Include verwenden
*--------------------------------------------------------------------*
* AD, 2024.02.16, NOTE-3524
* FM auf RFC umgestellt
*--------------------------------------------------------------------*
* AD, 2024.07.10 NOTE-3548
* Ausnahme /SCT/QP_CX_ERROR abfangen
*--------------------------------------------------------------------*

  TRY.
      "Daten lesen
      go_data->get_data( EXPORTING is_input    = VALUE #( guid             = is_root_select-guid
                                                          sel_tables       = gc->select_tables-arc
                                                          read_db          = abap_true
                                                          read_hierarchy   = abap_true )
                         IMPORTING es_db_data  = es_db_data
                                   et_qvc_data = et_qvc_data ).

    CATCH /sct/qp_cx_error.
      gx->do_handle_internal_errorx( ).
  ENDTRY.

ENDFUNCTION.
