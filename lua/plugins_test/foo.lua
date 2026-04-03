return {
  "foo",
  deps = {
    {
      "bar",
      opts = { one = true, two = true },
    },
  },
  config = function()
    print("load foo")
  end,
}
