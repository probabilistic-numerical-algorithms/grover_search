--  Grover's Resonant Search Algorithm Package
--  Language: Ada 2022
--  Direct Contact Action Epistemic State Vector Search

pragma ada_2022;

generic
   type real is digits <>;
   with function predicate (index : natural) return boolean;
package grover_search is

   type amplitude_array is array (natural range <>) of real;

   --  Subprogram to run the entire Grover's search algorithm.
   --  N is the number of elements.
   --  Iterations is the number of search steps to perform.
   --  Perturbation is the noise coefficient for self-healing perturbations.
   --  Returns the index of the found element.
   function search (n            : positive;
                    iterations   : positive;
                    perturbation : real)
     return natural
     with
       pre  => n > 0 and iterations > 0 and perturbation >= 0.0,
       post => (if search'result /= 0 then predicate (search'result));

   --  Subprograms for individual steps (exported for verification)
   procedure initialize (amplitudes : in out amplitude_array)
   with
     pre  => amplitudes'length > 0,
     post => (for all i in amplitudes'range => amplitudes (i) > 0.0);
   
--------   procedure apply_predicate (amplitudes : in out amplitude_array)
--------   with
--------     pre  => amplitudes'length > 0,
--------     post => amplitudes'length = amplitudes'old'length;
      
   procedure apply_diffusion (amplitudes : in out amplitude_array)
   with
     pre  => amplitudes'length > 0,
     post => (amplitudes'first = amplitudes'old'first
              and amplitudes'last = amplitudes'old'last);

end grover_search;
