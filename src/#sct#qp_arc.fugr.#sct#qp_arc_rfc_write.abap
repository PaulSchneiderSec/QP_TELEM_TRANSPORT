FUNCTION /sct/qp_arc_rfc_write.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     VALUE(IS_ROOT_SELECT) TYPE  /SCT/QP_S_DATA_SELECT
*"     VALUE(IS_DB_DATA) TYPE  /SCT/QP_S_DB_DATA OPTIONAL
*"     VALUE(IT_ARCNODE) TYPE  /SCT/QP_T_ARCNODE OPTIONAL
*"     VALUE(IV_TEST_MODE) TYPE  BOOLE_D OPTIONAL
*"     VALUE(IV_COMMIT_WORK) TYPE  /SCT/QP_COMMIT_WORK
*"----------------------------------------------------------------------

*--------------------------------------------------------------------*
* Änderungslog
*--------------------------------------------------------------------*
* ES20201004 Note 3027  https://service.secat.de/software/projects/NOTE/issues/NOTE-3027
* Archivierung Versionen via RFC Mandanten fehlerhaften
*--------------------------------------------------------------------*
* AD, 2020.01.07, NOTE 3027
* TOOLS-Methoden vewenden
*--------------------------------------------------------------------*
* MD, 2021.01.08: N3027 Parameter it_qvc_data entfernt
*--------------------------------------------------------------------*
* AD, 2021.03.03, NOTE 3108
* Folgeprozesse
*--------------------------------------------------------------------*
* AD, 2024.07.10, NOTE-3548
* COMMIT nicht steuerbar
*--------------------------------------------------------------------*

  TRY.
      "Test?
      IF iv_test_mode = abap_true.
        RETURN.
      ENDIF.

      "Daten speichern
      CALL METHOD go_data->save
        EXPORTING
          is_db_data = is_db_data.

      IF iv_commit_work = abap_true.
        COMMIT WORK AND WAIT.
      ENDIF.
    CATCH /sct/qp_cx_error.
      gx->do_handle_internal_errorx( ).
  ENDTRY.
ENDFUNCTION.
