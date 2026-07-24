pragma ada_2022;

with ada.text_io; use ada.text_io;
with entropy;

procedure demo_entropy is

 type real is new long_float;

 package real_io is new ada.text_io.float_io (real);
 use real_io;

 package real_entropy is new entropy (real);
 use real_entropy;

 procedure demo_uniform_real is
 begin
  put_line ("uniform_real (-10.0, 10.0)");
  put_line ("--------------------------");
  for i in 1 .. 100 loop
    put (
      item => uniform_real (-10.0, 10.0),
      fore => 3, aft => 4, exp => 0
    );
    put (" ");
  end loop;
  new_line;
 end demo_uniform_real;

 procedure demo_uniform_integer is
 begin
  put_line ("uniform_integer (-10, 10)");
  put_line ("-------------------------");
  for i in 1 .. 100 loop
    put (integer'image (uniform_integer (-10, 10)));
    put (" ");
  end loop;
  new_line;
 end demo_uniform_integer;

begin
  new_line;
  demo_uniform_real;
  new_line;
  demo_uniform_integer;
  new_line;
end demo_entropy;
