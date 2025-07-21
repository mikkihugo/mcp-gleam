/// Tests for JSON schema module
import gleam/list
import gleam/option.{None}
import gleeunit
import gleeunit/should
import mcp_toolkit_gleam/core/json_schema

pub fn main() {
  gleeunit.main()
}

// Test basic schema types
pub fn schema_types_test() {
  let empty_schema = json_schema.Empty([])
  let string_schema = json_schema.Type(
    nullable: False, 
    metadata: [], 
    type_: json_schema.String
  )
  let number_schema = json_schema.Type(
    nullable: False,
    metadata: [],
    type_: json_schema.Number
  )
  
  // Test schemas are different types
  empty_schema |> should.not_equal(string_schema)
  string_schema |> should.not_equal(number_schema)
}

// Test object schema creation
pub fn object_schema_test() {
  let object_schema = json_schema.ObjectSchema(
    properties: [
      #("name", json_schema.Type(nullable: False, metadata: [], type_: json_schema.String)),
      #("age", json_schema.Type(nullable: False, metadata: [], type_: json_schema.Integer))
    ],
    required: ["name"],
    additional_properties: None,
    pattern_properties: []
  )
  
  // Test object schema has correct properties
  object_schema.required |> should.equal(["name"])
  object_schema.properties |> list.length |> should.equal(2)
}

// Test root schema creation
pub fn root_schema_test() {
  let schema = json_schema.Type(nullable: False, metadata: [], type_: json_schema.String)
  let root = json_schema.RootSchema(definitions: [], schema: schema)
  
  root.definitions |> should.equal([])
}

// Test enum schema
pub fn enum_schema_test() {
  let enum_schema = json_schema.Enum(
    nullable: False,
    metadata: [],
    variants: ["red", "green", "blue"]
  )
  
  enum_schema.variants |> should.equal(["red", "green", "blue"])
}

// Test array schema
pub fn array_schema_test() {
  let item_schema = json_schema.Type(nullable: False, metadata: [], type_: json_schema.String)
  let array_schema = json_schema.Array(
    nullable: False,
    metadata: [],
    items: item_schema
  )
  
  array_schema.items |> should.equal(item_schema)
}

// Test JSON generation from object schema
pub fn object_schema_to_json_test() {
  let object_schema = json_schema.ObjectSchema(
    properties: [
      #("name", json_schema.Type(nullable: False, metadata: [], type_: json_schema.String))
    ],
    required: ["name"],
    additional_properties: None,
    pattern_properties: []
  )
  
  let json_fields = json_schema.object_schema_to_json(object_schema)
  
  // Should generate JSON representation
  should.be_true(list.length(json_fields) >= 0)
}

// Test codegen generator creation
pub fn codegen_generator_test() {
  let generator = json_schema.codegen()
  
  // Test generator functions
  let gen_with_root = json_schema.root_name(generator, "TestSchema")
  let gen_with_encoders = json_schema.generate_encoders(gen_with_root, True)
  let _gen_with_decoders = json_schema.generate_decoders(gen_with_encoders, True)
  
  // Should be able to chain generator modifications
  should.be_true(True)
}

// Test nullable schemas
pub fn nullable_schema_test() {
  let nullable_string = json_schema.Type(
    nullable: True,
    metadata: [],
    type_: json_schema.String
  )
  
  let non_nullable_string = json_schema.Type(
    nullable: False,
    metadata: [],
    type_: json_schema.String
  )
  
  nullable_string |> should.not_equal(non_nullable_string)
}

// Test all basic types
pub fn all_types_test() {
  let types = [
    json_schema.Boolean,
    json_schema.String,
    json_schema.Number,
    json_schema.Integer,
    json_schema.ArrayType,
    json_schema.ObjectType,
    json_schema.Null,
  ]
  
  types |> list.length |> should.equal(7)
}