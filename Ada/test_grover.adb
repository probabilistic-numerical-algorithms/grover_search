pragma ada_2022;

with ada.text_io; use ada.text_io;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with grover_search;

procedure test_grover is

   type real is new long_float;

   --  A dynamic target index used by the predicate to support multiple tests
   --  without needing multiple package instantiations.
   Active_Target_Index : natural := 4;

   --  A robust dictionary mapping indexes to words
   function get_word (index : natural) return string
   with
     pre => index in 0 .. 7 | 99
   is
      Result : Unbounded_String;
   begin
      case index is
         when 0 => Result := To_Unbounded_String ("IS");
         when 1 => Result := To_Unbounded_String ("THE");
         when 2 => Result := To_Unbounded_String ("INSIGHT");
         when 3 => Result := To_Unbounded_String ("OF");
         when 4 => Result := To_Unbounded_String ("PHYSICS");
         when 5 => Result := To_Unbounded_String ("PURPOSE");
         when 6 => Result := To_Unbounded_String ("TRUTH");
         when 7 => Result := To_Unbounded_String ("BEAUTY");
         when others => Result := Null_Unbounded_String;
      end case;
      return To_String (Result);
   end get_word;

   --  Our predicate function matching the generic signature
   function my_predicate (index : natural) return boolean
   with
     pre => index <= 100
   is
      Result : Boolean := False;
   begin
      Result := (index = Active_Target_Index);
      return Result;
   end my_predicate;

   --  Instantiate the generic Grover's Search package with our predicate
   package solver is new grover_search (predicate => my_predicate);

   result_index : natural;
   pass_count   : natural := 0;
   test_count   : natural := 0;

   --  Helper to print test header
   procedure print_header (title : string)
   with
     pre => title'length > 0
   is
   begin
      put_line ("-------------------------------------------------------------");
      put_line ("TEST: " & title);
      put_line ("-------------------------------------------------------------");
   end print_header;

begin
   put_line ("=============================================================");
   put_line ("  GROVER'S RESONANT SEARCH COMPREHENSIVE TEST SUITE (ADA 2022)");
   put_line ("=============================================================");
   new_line;

   put_line ("Register layout (Max Entropy Initial State):");
   for i in 0 .. 7 loop
      put_line ("  M" & i'image & ": '" & get_word (i) & "'");
   end loop;
   new_line;

   --------------------------------------------------------------------------
   --  TEST 1: Baseline Target Verification (PHYSICS at Index 4)
   --------------------------------------------------------------------------
   test_count := test_count + 1;
   print_header ("Baseline Target Verification (Target = 'PHYSICS', Index 4)");
   Active_Target_Index := 4;
   
   put_line ("Searching via predicate for index 4 ('PHYSICS')...");
   result_index := solver.search
     (n            => 8,
      iterations   => 2,
      perturbation => 0.1);

   if result_index = 4 then
      put_line ("SUCCESS: Correctly found index 4 with retrieved word: '" & get_word (result_index) & "'");
      pass_count := pass_count + 1;
   else
      put_line ("FAILURE: Expected index 4, got: " & result_index'image);
   end if;
   new_line;

   --------------------------------------------------------------------------
   --  TEST 2: Exhaustive All-Index Coverage Scan
   --------------------------------------------------------------------------
   test_count := test_count + 1;
   print_header ("Exhaustive Position Coverage Scan (M0 through M7)");
   
   declare
      scan_success : boolean := true;
   begin
      for i in 0 .. 7 loop
         Active_Target_Index := i;
         result_index := solver.search
           (n            => 8,
            iterations   => 2,
            perturbation => 0.15);

         if result_index = i then
            put_line ("  - Target M" & i'image & " ('" & get_word(i) & "') -> FOUND correctly.");
         else
            put_line ("  - Target M" & i'image & " -> FAILED. Got: " & result_index'image);
            scan_success := false;
         end if;
      end loop;

      if scan_success then
         put_line ("SUCCESS: Exhaustive scan of all 8 positions passed successfully!");
         pass_count := pass_count + 1;
      else
         put_line ("FAILURE: Some positions failed the exhaustive scan.");
      end if;
   end;
   new_line;

   --------------------------------------------------------------------------
   --  TEST 3: Statistical Performance Sweep (100 Trials)
   --------------------------------------------------------------------------
   test_count := test_count + 1;
   print_header ("Statistical Performance Sweep (100 Trials, Target = 'TRUTH' at M6)");
   Active_Target_Index := 6;
   
   declare
      trials : constant positive := 100;
      success_count : natural := 0;
      success_rate : real;
   begin
      for t in 1 .. trials loop
         result_index := solver.search
           (n            => 8,
            iterations   => 2,
            perturbation => 0.1);
         if result_index = 6 then
            success_count := success_count + 1;
         end if;
      end loop;

      success_rate := real(success_count) * real (100) / real(trials);

      put_line ("Total trials run: " & trials'image);
      put_line ("Successful acquisitions: " & success_count'image);
      put_line ("Empirical success rate: " & success_rate'image & "%");

      if success_count = trials then
         put_line ("SUCCESS: Perfect 100% robust acquisition rate under phase noise!");
         pass_count := pass_count + 1;
      else
         put_line ("WARNING: Acquisition rate is: " & success_rate'image & "%");
      end if;
   end;
   new_line;

   --------------------------------------------------------------------------
   --  TEST 4: Graceful Termination on Non-Existent Target (Predicate Never True)
   --------------------------------------------------------------------------
   test_count := test_count + 1;
   print_header ("Graceful Termination on Non-Existent Target");
   Active_Target_Index := 99; -- Outside standard 0 .. 7 bounds, predicate never true
   
   put_line ("Executing search on non-existent target (expecting termination)...");
   result_index := solver.search
     (n            => 8,
      iterations   => 2,
      perturbation => 0.15);

   -- Since the predicate is never true, the search must eventually exit the retry loop 
   -- and return 0 (standard fallback).
   if result_index = 0 then
      put_line ("SUCCESS: Search terminated gracefully after max retry attempts, returned 0.");
      pass_count := pass_count + 1;
   else
      put_line ("FAILURE: Expected fallback 0, got: " & result_index'image);
   end if;
   new_line;

   --------------------------------------------------------------------------
   --  FINAL SUMMARY
   --------------------------------------------------------------------------
   put_line ("=============================================================");
   put_line ("  TEST SUITE RESULTS");
   put_line ("=============================================================");
   put_line ("Tests run:  " & test_count'image);
   put_line ("Tests passed:" & pass_count'image);
   
   if pass_count = test_count then
      put_line ("OVERALL STATUS: ALL TESTS PASSED");
   else
      put_line ("OVERALL STATUS: FAILURE");
   end if;
   put_line ("=============================================================");

end test_grover;
