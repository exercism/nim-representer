import unittest
import representer/mapping


suite "Identifier map testing":
  setup:
    var map: IdentMap

  test "Initialization":
    check map.len == 0

  test "Insert Identifier":
    map["x".NormalizedIdent] = "placeholder_1"
    map["y".NormalizedIdent] = "placeholder_2"
    check map.len == 2

  test "First Letter Capital":
    map["x".NormalizedIdent] = "placeholder_0"
    map["X".NormalizedIdent] = "placeholder_1"
    check map.len == 2

  test "Other Letter Capitals":
    map["hello".NormalizedIdent] = "placeholder_1"
    map["hElLO".NormalizedIdent] = "placeholder_100"
    map["Hello".NormalizedIdent] = "placeholder_2"
    map["HELLo".NormalizedIdent] = "placeholder_200"
    check map.len == 2
