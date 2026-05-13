class /SCT/QP_CL_QV_CUST_SERVICE_ARC definition
  public
  inheriting from /SCT/QP_CL_CUST
  create public

  global friends /SCT/QP_CL_QV_CUST_SERVICE .

public section.

  data MV_CURRENT_ARCSID type /SCT/QP_ARC_SESSION_ID .

  methods SET_ACTIVE
    importing
      !IV_ARCSID type /SCT/QP_ARC_SESSION_ID .
  methods CONSTRUCTOR
    raising
      /SCT/QP_CX_ERROR .
protected section.

  types:
    BEGIN OF ty_cust_arcid.
    TYPES: arcsid      TYPE /sct/qp_arc_session_id,
           customizing TYPE /sct/qp_s_qv_customizing,
           END OF ty_cust_arcid .
  types:
    tty_cust_arcid TYPE HASHED TABLE OF ty_cust_arcid WITH UNIQUE KEY arcsid .

  class-data MT_CUST type TTY_CUST_ARCID .
  data MO_ARC type ref to /SCT/QP_IF_ARC .

  methods SET_DB_PROCESSED
    changing
      !CR_CUSTOMIZING type ref to /SCT/QP_S_QV_CUSTOMIZING .

  methods DO_LOAD_FROM_DB
    redefinition .
  methods GENB_STATUS
    redefinition .
  PRIVATE SECTION.
ENDCLASS.



CLASS /SCT/QP_CL_QV_CUST_SERVICE_ARC IMPLEMENTATION.


  METHOD constructor.

    super->constructor( ).

    /sct/qp_cl_factory=>get_instances( IMPORTING eo_arc = mo_arc ).

    mv_current_arcsid = '$$$'.

*   initialisieren, Arcsid = space -> Aktuelles Customizing
    set_active( iv_arcsid = space ).

  ENDMETHOD.


  METHOD do_load_from_db.
*--------------------------------------------------------------------*
* Änderungslog
*--------------------------------------------------------------------*
* MD, 2019.05.08: N2143 Processed-Tabellen berücksichtigen
* MD, 2019.05.09: N2143 Bei init. ARCID oder fehlendem Cust von DB laden
*--------------------------------------------------------------------*
* AD, 2019.08.09, NOTE 2222
* Statische Attribute
*--------------------------------------------------------------------*
*--------------------------------------------------------------------*
* ES20230615 NOTE-3410 Simplifizierung
* Prüftabelle für Generierungsmethoden gelöscht
*--------------------------------------------------------------------*
* AD, 2024.03.01, NOTE-1372, Umzug ins SHMO
*--------------------------------------------------------------------*

    CLEAR mr_customizing->*.

*   Daten aus Archiv lesen
    IF mv_current_arcsid IS NOT INITIAL.                "MD190509 N2143 INS

      mo_arc->read_customizing( EXPORTING iv_arcsid     = mv_current_arcsid
                                IMPORTING es_cust_db    = DATA(ls_cust_db)
                                          et_arc_return = DATA(lt_return) ).

      IF ls_cust_db IS NOT INITIAL.                     "MD190509 N2143 INS


* Erst Daten übertragen
        MOVE-CORRESPONDING ls_cust_db TO mr_customizing->*.

* Dann die DBTabellen als verarbeitet markieren
        CALL METHOD set_db_processed
          CHANGING
            cr_customizing = mr_customizing.    "MD190508 N2143 INS

      ENDIF.

    ENDIF.

    "ktueller User setzen
    do_load_tusrpref( ).

    "Buffer-Tabellen alle aufbauen
    CALL METHOD super->do_load_from_db.

    "Überflüssigen Tabellen wieder löschen.
    CLEAR : mr_customizing->tdid, mr_customizing->ttxit.
    CLEAR : mr_customizing->tgruelm.
    CLEAR : mr_customizing->tresuser, mr_customizing->usr21, mr_customizing->adrp.
    CLEAR : mr_customizing->tname.
    CLEAR : mr_customizing->tvblock.
    CLEAR : mr_customizing->tauthg.
    CLEAR : mr_customizing->tj01, mr_customizing->tj03, mr_customizing->tj04, mr_customizing->tj05, mr_customizing->tj06, mr_customizing->tj07.
    CLEAR : mr_customizing->tttyp, mr_customizing->tttypt.
    CLEAR : mr_customizing->trespon, mr_customizing->trespont.

  ENDMETHOD.


  METHOD genb_status.

    CHECK mr_customizing->tj0x[] IS INITIAL.

*   Puffer aufbauen
    CALL METHOD do_select_status
      EXPORTING
        iv_spras = mv_spras
      CHANGING
*       FT20170424 Note 1324 BoC
*       cs_cust  = ms_customizing.
        cs_cust  = mr_customizing->*.
*       FT20170424 Note 1324 EoC

    CALL METHOD gen_status
      EXPORTING
        iv_spras       = sy-langu
      CHANGING
*       FT20170424 Note 1324 BoC
*       cs_customizing = ms_customizing.
        cs_customizing = mr_customizing->*.
*       FT20170424 Note 1324 EoC

  ENDMETHOD.


  METHOD set_active.
*--------------------------------------------------------------------*
* Änderungslog
*--------------------------------------------------------------------*
* MD, 2019.05.09: N2143 DO_LOAD_FROM_DB immer ausführen
*--------------------------------------------------------------------*
* AD, 2024.07.17 NOTE-3548
* Ausnahme /SCT/QP_CX_ERROR entfernt
*--------------------------------------------------------------------*

    IF iv_arcsid NE mv_current_arcsid.

      mv_current_arcsid = iv_arcsid.

*     Neue ARCID :
*     Customizing zur ArcsID einlesen
      READ TABLE mt_cust ASSIGNING FIELD-SYMBOL(<fs_cust>)
      WITH TABLE KEY arcsid = iv_arcsid.
      IF sy-subrc NE 0.

*       Neue Customizing-Daten anlegen
        DATA(ls_cust) = VALUE ty_cust_arcid( arcsid = iv_arcsid ).

        INSERT ls_cust INTO TABLE mt_cust ASSIGNING <fs_cust>.

*       Referenz setzen
        mr_customizing = REF #( <fs_cust>-customizing ).

*       CustomizingDaten aus dem Archiv (oder von der DB bei initialer ARCSID) vollständig laden
        do_load_from_db( ).   "MD190509 N2143 CHG Immer laden

      ELSE.
*       Referenz setzen
        mr_customizing = REF #( <fs_cust>-customizing ).
      ENDIF.
    ENDIF.

  ENDMETHOD.


  METHOD set_db_processed.
*--------------------------------------------------------------------*
* Änderungslog
*--------------------------------------------------------------------*
* MD, 2019.05.08: N2143 Angelegt
*--------------------------------------------------------------------*

    DATA(lo_struct) = CAST cl_abap_structdescr( cl_abap_typedescr=>describe_by_data( cr_customizing->* ) ).
    LOOP AT lo_struct->components ASSIGNING FIELD-SYMBOL(<fs_component>).
      INSERT <fs_component>-name INTO TABLE cr_customizing->db_processed.  " eindeutige Einträge durch Hashed Key sichergestellt
    ENDLOOP.

  ENDMETHOD.
ENDCLASS.
