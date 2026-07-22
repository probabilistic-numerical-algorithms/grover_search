pragma ada_2022;

with ada.text_io;
with ada.command_line;
with entropy;
with grover_search;

procedure test_grover_2 is

  use ada.text_io;
  use ada.command_line;

  type real is new long_float;
  type integer_array is array (integer range <>) of integer;

  package real_entropy is new entropy (real);
  use real_entropy;

  failed : boolean := false;
  m, n   : positive;

  function to_exit_status (b : boolean)
  return exit_status is
  begin
    return (if b then success else failure);
  end to_exit_status;

  procedure fill (arr : in out integer_array) is
  begin
    for i in arr'range loop
      arr(i) := i;
    end loop;
  end fill;

  function integer_log2 (n : positive)
  return natural is
     result : natural := 0;
     tmp    : natural := n;
  begin
     tmp := @ / 2;
     while 0 < tmp loop
        result := @ + 1;
        tmp := @ / 2;
     end loop;
     return result;
  end integer_log2;

  function next_power_of_two (n : natural)
  return positive is
    type unsigned_32 is mod 2**32;
    tmp    : unsigned_32;
    result : positive;
  begin
    if n <= 1 then
       result := 1;
    else
       tmp := unsigned_32 (n) - 1;
       tmp := @ or (@ / 2);
       tmp := @ or (@ / 4);
       tmp := @ or (@ / 16);
       tmp := @ or (@ / 256);
       tmp := @ or (@ / 65536);

       if tmp + 1 = 0 then
          raise constraint_error
            with "next power of 2 overflows 32-bit limit";
       end if;

       result := positive (tmp + 1);
    end if;

    return result;
  end next_power_of_two;

begin
  if argument_count = 0 then
    put_line ("Expected a positive number.");
    failed := true;
  elsif argument_count /= 1 then
    put_line ("Expected only one argument.");
    failed := true;
  else
    declare
    begin
      m := positive'value (argument (1));
      n := next_power_of_two (m);
    exception when constraint_error =>
      put_line ("Expected a positive number.");
      failed := true;
    end;
    if not failed then
      declare
        arr    : integer_array (0 .. n - 1);
        target : integer range 0 .. m - 1;

      begin
        target := uniform_integer (0, m - 1);
        target := uniform_integer (0, m - 1);
        target := uniform_integer (0, m - 1);
        target := uniform_integer (0, m - 1);
        declare
          j      : integer range 0 .. n - 1;

          function equals_one (index : natural)
          return boolean is
          begin
            return (arr(index) = target);
          end equals_one;

          package integer_array_search is
            new grover_search (real => real,
                               predicate => equals_one);
          use integer_array_search;

        begin
          fill (arr);
          j := search (n => integer_log2 (n),
                       iterations => 2,
                       perturbation => 0.1);
          put_line (n'image);
          put_line (integer'image (integer_log2 (n)));
          put_line (target'image);
          put_line (j'image);
          if arr(j) = target then
            put_line ("success");
          else
            put_line ("failure");
          end if;
        end;
      end;
    end if;
  end if;
  set_exit_status (to_exit_status (not failed));
end test_grover_2;
