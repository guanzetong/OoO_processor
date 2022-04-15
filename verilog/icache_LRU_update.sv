/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  LRU_update.sv                                       //
//                                                                     //
//  Description :  Generate the LRU bits of the next cycle according   //
//                 to the use history of ways in a set and the access  //
//                 to each way.                                        //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module icache_LRU_update #(
    parameter   C_CACHE_SASS        =   `ICACHE_SASS                            ,
    parameter   C_USE_HISTORY_WIDTH =   ((C_CACHE_SASS*(C_CACHE_SASS-1)) >> 1)
) (
    input   logic   [C_USE_HISTORY_WIDTH-1:0]   use_history         ,
    input   logic   [C_CACHE_SASS-1:0]          access              ,
    output  logic   [C_USE_HISTORY_WIDTH-1:0]   next_use_history    ,
    output  logic   [C_CACHE_SASS-1:0]          next_lru            
);

// ====================================================================
// Signal Declarations Start
// ====================================================================
    logic   [C_CACHE_SASS-1:0]      expand      [0:C_CACHE_SASS-1]  ;   //  LRU check matrix
    integer                         i                               ;
    integer                         j                               ;
    integer                         offset                          ;   //  Offset in use_history
// ====================================================================
// Signal Declarations End
// ====================================================================

// ====================================================================
// RTL Logic Start
// ====================================================================
    always_comb begin
        // Expand the use_history to a C_CACHE_SASS * C_CACHE_SASS array
        offset  =   0;
        for (int unsigned i = 0; i < C_CACHE_SASS; i = i + 1) begin
            // Diagnal
            expand[i][i] = 1'b1;
            // Upper triangle
            for (int unsigned j = i + 1; j < C_CACHE_SASS; j = j + 1) begin
                expand[i][j]    =   use_history[offset+j-i-1];
            end
            // Lower triangle
            for (int unsigned j = 0; j < i; j = j + 1) begin
                expand[i][j]    =   !expand[j][i];
            end
            offset = offset + C_CACHE_SASS - i - 1;
        end 

        // Update Matrix if there is an access
        for (i = 0; i < C_CACHE_SASS; i = i + 1) begin
            if (access[i]) begin
                for (j = 0; j < C_CACHE_SASS; j = j + 1) begin
                    if (i != j) begin
                        expand[i][j] = 1'b0;
                    end
                end

                for (j = 0; j < C_CACHE_SASS; j = j + 1) begin
                    if (i != j) begin
                        expand[j][i] = 1'b1;
                    end
                end
            end
        end

        // Generate the value of use_history to be updated
        offset = 0;
        for (i = 0; i < C_CACHE_SASS; i = i + 1) begin
            for (j = i + 1; j < C_CACHE_SASS; j = j + 1) begin
                next_use_history[offset+j-i-1] = expand[i][j];
            end
            offset = offset + C_CACHE_SASS - i - 1;
        end

        // Generate the LRU bits
        for (i = 0; i < C_CACHE_SASS; i = i + 1) begin
            next_lru[i] = &expand[i];
        end
    end
// ====================================================================
// RTL Logic End
// ====================================================================


endmodule
