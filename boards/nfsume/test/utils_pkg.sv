/* vivado doesn't support streaming operators in always block */
package utils_pkg;

	/* bit reverse */
	function [7:0] reverse8 (
		input [7:0] a
	);
	begin
		reverse8[7:0] = { a[0], a[1], a[2], a[3], a[4], a[5], a[6], a[7] };
	end
	endfunction

endpackage :utils_pkg

