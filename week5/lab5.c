int control_D2( lua_State *L ) {
    int numargs = lua_gettop(L);

    printf("control_d2 called with %d args\n", numargs);
    uint32_t volatile *enableReg = (uint32_t volatile *) (0x400E1000 + 0x0004);
    *enableReg = (1 << 16);

    printf("wrote to enableReg\n");

    uint32_t volatile *enableOutputReg = (uint32_t volatile *)(0x400E1000 + 0x0044);
    *enableOutputReg = (1 << 16);

    printf("wrote to enableOutputReg\n");

    uint32_t volatile *toggleReg = (uint32_t volatile *) (0x400E1000 + 0x005c);

    printf("made to toggleReg\n");

    //now the loop
    while( 1 ) {
    	*toggleReg = (1 << 16);
    	//printf("toggling");
    	//sleep(40);
    }
    return 0;
}