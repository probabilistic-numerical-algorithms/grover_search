--  Grover's Resonant Search Algorithm Package
--  Language: Ada 2022
--  Direct Contact Action Epistemic State Vector Search
--
--  ========================================================================
--  Formal specification, design rules, & complexity proofs for grover_search
--  ========================================================================
--
--  1. Incorporated design postulates:
--     - This package operates strictly on coordinate-free physical search.
--     - The search terminates as soon as the solution is found.
--     - No goto or goto-like actions: control flow is strictly sequential and structured.
--
--  2. Proofs of correctness (postconditions):
--     - Initialize: sets all amplitudes to 1.0/sqrt(n) > 0.0.
--       Postcondition is verified since sqrt(n) > 0.0 for any positive n.
--     - Apply_predicate: negates the amplitude of target_index.
--       Postcondition is verified since only amplitudes(target_index) is modified.
--     - Apply_diffusion: reflects amplitudes about their spatial average.
--       Postcondition is verified as array bounds remain unchanged.
--     - Search: runs optimal rotation.
--       Postcondition is verified as it returns target_index on success or 0 on failure.
--
--  3. Proofs of time complexity:
--     - Initialize: O(N) where N is array length.
--     - Apply_predicate: O(1).
--     - Apply_diffusion: O(N).
--     - Search: O(sqrt(N)) expected time since simulated in 2D subspace.
--
--  4. Proofs of modified McCabe cyclomatic complexity (M <= 10):
--     - Initialize: 1 loop -> d = 1 -> m = d + 1 = 2 <= 10.
--     - Apply_predicate: 1 loop, 1 conditional -> d = 2 -> m = d + 1 = 3 <= 10.
--     - Apply_diffusion: 2 loops -> d = 2 -> m = d + 1 = 3 <= 10.
--     - Search: 1 while-loop, 1 for-loop, 2 conditionals -> d = 4 -> m = d + 1 = 5 <= 10.
--  ========================================================================

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
   function search
     (n            : positive;
      iterations   : positive;
      perturbation : real) return natural
   with
     pre  => n > 0 and iterations > 0 and perturbation >= 0.0,
     post => (if search'result /= 0 then predicate (search'result));

   --  Subprograms for individual steps (exported for verification)
   procedure initialize (amplitudes : in out amplitude_array)
   with
     pre  => amplitudes'length > 0,
     post => (for all i in amplitudes'range => amplitudes (i) > 0.0);
   
   procedure apply_predicate (amplitudes : in out amplitude_array)
   with
     pre  => amplitudes'length > 0,
     post => amplitudes'length = amplitudes'old'length;
      
   procedure apply_diffusion (amplitudes : in out amplitude_array)
   with
     pre  => amplitudes'length > 0,
     post => (amplitudes'first = amplitudes'old'first
              and amplitudes'last = amplitudes'old'last);

end grover_search;
