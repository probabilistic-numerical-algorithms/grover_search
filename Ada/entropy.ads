pragma ada_2022;

generic
  type real is digits <>;
package entropy is

  type entropy_seed is mod 2 ** 64;

  protected type safe_seed is
    procedure set (seed : in entropy_seed);
    function get return entropy_seed;
    procedure update;
  private
    value : entropy_seed := 0;
  end safe_seed;

  global_seed : safe_seed;

  function uniform_real (least    : in real := 0.0;
                         greatest : in real := real'pred (1.0))
    return real
    with pre => least <= greatest,
         post => (least <= uniform_real'result
                  and uniform_real'result <= greatest);

  function uniform_integer (least    : in integer;
                            greatest : in integer)
    return integer
    with pre => least <= greatest,
         post => (least <= uniform_integer'result
                  and uniform_integer'result <= greatest);

end entropy;
