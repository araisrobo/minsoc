//
// Width of address bus
//
`define TC_AW		32

//
// Width of data bus
//
`define TC_DW		32

//
// Width of byte select bus
//
`define TC_BSW		4

//
// Width of WB target inputs (coming from WB slave)
//
// data bus width + ack + err
//
`define TC_TIN_W	`TC_DW+1+1

//
// Width of WB initiator inputs (coming from WB masters)
//
// cyc + stb + address bus width +
// byte select bus width + we + data bus width
// (remove wb_err)
`define TC_IIN_W	1+1+`TC_AW+`TC_BSW+1+`TC_DW


