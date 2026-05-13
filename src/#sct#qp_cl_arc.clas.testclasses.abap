*CLASS ltc_arc_test DEFINITION FINAL FOR TESTING
*  INHERITING FROM /sct/qp_cl_test_arc
*  DURATION LONG
*  RISK LEVEL HARMLESS.
*
*  PROTECTED SECTION.
*
*    METHODS read_customizing REDEFINITION.
*    METHODS _read_customizing_specific REDEFINITION.
*    METHODS _read_specific REDEFINITION.
*    METHODS full_archive_run REDEFINITION.
*
*  PRIVATE SECTION.
*
*ENDCLASS.
*
*
*CLASS ltc_arc_test IMPLEMENTATION.
*
*  METHOD full_archive_run.
*
*    super->full_archive_run( ).
*
*  ENDMETHOD.
*
*  METHOD read_customizing.
*
*    super->read_customizing( ).
*
*  ENDMETHOD.
*
*  METHOD _read_customizing_specific.
*
*    super->_read_customizing_specific( ).
*
*  ENDMETHOD.
*
*  METHOD _read_specific.
*
*    super->_read_specific( ).
*
*  ENDMETHOD.
*
*ENDCLASS.
