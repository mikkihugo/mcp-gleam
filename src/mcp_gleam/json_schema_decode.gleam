// //// <https://json-schema.org/>
// ////
// //// <https://datatracker.ietf.org/doc/html/draft-bhutton-json-schema-00>

// import gleam/dict.{type Dict}
// import gleam/dynamic/decode.{type Decoder, type Dynamic}
// import gleam/json.{type Json}
// import gleam/list
// import gleam/option.{type Option, None, Some}
// import gleam/result
// import gleam/string

// pub type RootSchema {
//   RootSchema(definitions: List(#(String, Schema)), schema: Schema)
// }

// pub type Type {
//   /// `true` or `false`
//   Boolean
//   /// JSON strings
//   String
//   /// JSON numbers
//   Number
//   /// JSON integers
//   Integer
//   /// JSON arrays
//   ArrayType
//   /// JSON objects
//   ObjectType
//   /// JSON null values
//   Null
// }

// pub type Schema {
//   /// Any value. The empty form is like a Java Object or TypeScript any.
//   Empty(metadata: List(#(String, Dynamic)))
//   /// A simple built-in type. The type form is like a Java or TypeScript
//   /// primitive type.
//   Type(nullable: Bool, metadata: List(#(String, Dynamic)), type_: Type)
//   /// One of a fixed set of strings. The enum form is like a Java or TypeScript
//   /// enum.
//   Enum(
//     nullable: Bool,
//     metadata: List(#(String, Dynamic)),
//     variants: List(String),
//   )
//   // The properties form is like a Java class or TypeScript interface.
//   Object(
//     nullable: Bool,
//     metadata: List(#(String, Dynamic)),
//     schema: ObjectSchema,
//   )
//   /// A sequence of some other form. The items form is like a Java `List<T>`
//   /// or TypeScript `T[]`.
//   Array(nullable: Bool, metadata: List(#(String, Dynamic)), items: Schema)
//   /// A reference to another schema definition
//   Ref(nullable: Bool, metadata: List(#(String, Dynamic)), ref: String)
//   /// A schema that can be one of multiple schemas
//   OneOf(
//     nullable: Bool,
//     metadata: List(#(String, Dynamic)),
//     schemas: List(Schema),
//   )
//   /// A schema that must be all of multiple schemas
//   AllOf(
//     nullable: Bool,
//     metadata: List(#(String, Dynamic)),
//     schemas: List(Schema),
//   )
//   /// A schema that can be any of multiple schemas
//   AnyOf(
//     nullable: Bool,
//     metadata: List(#(String, Dynamic)),
//     schemas: List(Schema),
//   )
//   /// A schema that must not match the given schema
//   Not(nullable: Bool, metadata: List(#(String, Dynamic)), schema: Schema)
// }

// pub type ObjectSchema {
//   ObjectSchema(
//     properties: List(#(String, Schema)),
//     required: List(String),
//     additional_properties: Option(Schema),
//     pattern_properties: List(#(String, Schema)),
//   )
// }

// pub fn to_json(schema: RootSchema) -> Json {
//   let properties = schema_to_json(schema.schema)
//   let properties = case schema.definitions {
//     [] -> properties
//     definitions -> {
//       let definitions =
//         list.map(definitions, fn(definition) {
//           #(definition.0, json.object(schema_to_json(definition.1)))
//         })
//       [#("$defs", json.object(definitions)), ..properties]
//     }
//   }

//   json.object(properties)
// }

// pub fn object_schema_to_json(schema: ObjectSchema) -> List(#(String, Json)) {
//   let props_json = fn(props: List(#(String, Schema))) {
//     json.object(
//       list.map(props, fn(property) {
//         #(property.0, json.object(schema_to_json(property.1)))
//       }),
//     )
//   }

//   let ObjectSchema(
//     properties:,
//     required:,
//     additional_properties:,
//     pattern_properties:,
//   ) = schema

//   let data = []

//   let data = case pattern_properties {
//     [] -> data
//     p -> [#("patternProperties", props_json(p)), ..data]
//   }

//   let data = case additional_properties {
//     None -> data
//     Some(schema) -> [
//       #("additionalProperties", json.object(schema_to_json(schema))),
//       ..data
//     ]
//   }

//   let data = case required {
//     [] -> data
//     r -> [#("required", json.array(r, json.string)), ..data]
//   }

//   let data = case properties {
//     [] -> data
//     p -> [#("properties", props_json(p)), ..data]
//   }

//   data
// }

// fn schema_to_json(schema: Schema) -> List(#(String, Json)) {
//   case schema {
//     Empty(metadata:) ->
//       []
//       |> add_metadata(metadata)
//     Ref(nullable:, metadata:, ref:) ->
//       [#("$ref", json.string(ref))]
//       |> add_nullable(nullable)
//       |> add_metadata(metadata)
//     Type(nullable:, metadata:, type_:) ->
//       [#("type", type_to_json(type_))]
//       |> add_nullable(nullable)
//       |> add_metadata(metadata)
//     Enum(nullable:, metadata:, variants:) ->
//       [#("enum", json.array(variants, json.string))]
//       |> add_nullable(nullable)
//       |> add_metadata(metadata)
//     Array(nullable:, metadata:, items:) ->
//       [#("items", json.object(schema_to_json(items)))]
//       |> add_nullable(nullable)
//       |> add_metadata(metadata)
//     Object(nullable:, metadata:, schema:) ->
//       object_schema_to_json(schema)
//       |> add_nullable(nullable)
//       |> add_metadata(metadata)
//     OneOf(nullable:, metadata:, schemas:) ->
//       [
//         #(
//           "oneOf",
//           json.array(schemas, fn(s) { json.object(schema_to_json(s)) }),
//         ),
//       ]
//       |> add_nullable(nullable)
//       |> add_metadata(metadata)
//     AllOf(nullable:, metadata:, schemas:) ->
//       [
//         #(
//           "allOf",
//           json.array(schemas, fn(s) { json.object(schema_to_json(s)) }),
//         ),
//       ]
//       |> add_nullable(nullable)
//       |> add_metadata(metadata)
//     AnyOf(nullable:, metadata:, schemas:) ->
//       [
//         #(
//           "anyOf",
//           json.array(schemas, fn(s) { json.object(schema_to_json(s)) }),
//         ),
//       ]
//       |> add_nullable(nullable)
//       |> add_metadata(metadata)
//     Not(nullable:, metadata:, schema:) ->
//       [#("not", json.object(schema_to_json(schema)))]
//       |> add_nullable(nullable)
//       |> add_metadata(metadata)
//   }
// }

// // fn dynamic_to_json(value: Dynamic) -> Json {
// //   dynamic.unsafe_coerce(value)
// // }

// fn type_to_json(t: Type) -> Json {
//   json.string(case t {
//     Boolean -> "boolean"
//     String -> "string"
//     Number -> "number"
//     Integer -> "integer"
//     ArrayType -> "array"
//     ObjectType -> "object"
//     Null -> "null"
//   })
// }

// pub fn decoder(data: Dynamic) -> Result(RootSchema, List(dynamic.DecodeError)) {
//   dynamic.decode2(RootSchema, decode_definitions, fn(_) { Ok(Empty([])) })(data)
// }

// fn decode_definitions(
//   data: Dynamic,
// ) -> Result(List(#(String, Schema)), List(dynamic.DecodeError)) {
//   let defs_decoder = fn(data) {
//     use defs <- result.try(dynamic.field("$defs", dynamic.dynamic)(data))
//     dynamic.dict(dynamic.string, decode_schema)(defs)
//     |> result.map(dict.to_list)
//   }

//   let definitions_decoder = fn(data) {
//     use defs <- result.try(dynamic.field("definitions", dynamic.dynamic)(data))
//     dynamic.dict(dynamic.string, decode_schema)(defs)
//     |> result.map(dict.to_list)
//   }

//   defs_decoder(data)
//   |> result.lazy_or(fn() { definitions_decoder(data) })
// }

// fn decode_schema(data: Dynamic) -> Result(Schema, List(dynamic.DecodeError)) {
//   use data <- result.try(dynamic.dict(dynamic.string, dynamic.dynamic)(data))
//   let decoder =
//     key_decoder(data, "enum", decode_enum)
//     |> result.lazy_or(fn() { key_decoder(data, "$ref", decode_ref) })
//     |> result.lazy_or(fn() { key_decoder(data, "items", decode_array) })
//     |> result.lazy_or(fn() { key_decoder(data, "properties", decode_object) })
//     |> result.lazy_or(fn() { key_decoder(data, "oneOf", decode_one_of) })
//     |> result.lazy_or(fn() { key_decoder(data, "anyOf", decode_any_of) })
//     |> result.lazy_or(fn() { key_decoder(data, "allOf", decode_all_of) })
//     |> result.lazy_or(fn() { key_decoder(data, "not", decode_not) })
//     |> result.lazy_or(fn() { key_decoder(data, "type", decode_type) })
//     |> result.unwrap(fn() { decode_empty(data) })

//   decoder()
// }

// fn key_decoder(
//   dict: Dict(String, Dynamic),
//   key: String,
//   constructor: fn(Dynamic, Dict(String, Dynamic)) ->
//     Result(t, List(dynamic.DecodeError)),
// ) -> Result(fn() -> Result(t, List(dynamic.DecodeError)), Nil) {
//   case dict.get(dict, key) {
//     Ok(value) -> Ok(fn() { constructor(value, dict) })
//     Error(e) -> Error(e)
//   }
// }

// fn decode_object(
//   _props: Dynamic,
//   data: Dict(String, Dynamic),
// ) -> Result(Schema, List(dynamic.DecodeError)) {
//   use nullable <- result.try(get_nullable(data))
//   use metadata <- result.try(get_metadata(data))
//   dynamic.from(data)
//   |> decode_object_schema
//   |> result.map(Object(nullable, metadata, _))
// }

// pub fn decode_object_schema(
//   data: Dynamic,
// ) -> Result(ObjectSchema, List(dynamic.DecodeError)) {
//   let properties_field = fn(name, data) {
//     case dynamic.field(name, dynamic.dynamic)(data) {
//       Ok(d) -> decode_object_as_list(d, decode_schema) |> push_path(name)
//       Error(_) -> Ok([])
//     }
//   }

//   let additional_properties = fn(data) {
//     case dynamic.field("additionalProperties", dynamic.dynamic)(data) {
//       Ok(d) ->
//         case dynamic.bool(d) {
//           Ok(True) -> Ok(Some(Empty([])))
//           Ok(False) -> Ok(None)
//           Error(_) -> decode_schema(d) |> result.map(Some)
//         }
//         |> push_path("additionalProperties")
//       Error(_) -> Ok(Some(Empty([])))
//     }
//   }

//   let required_field = fn(data) {
//     case dynamic.field("required", dynamic.dynamic)(data) {
//       Ok(d) -> dynamic.list(dynamic.string)(d) |> push_path("required")
//       Error(_) -> Ok([])
//     }
//   }

//   dynamic.decode4(
//     ObjectSchema,
//     properties_field("properties", _),
//     required_field,
//     additional_properties,
//     properties_field("patternProperties", _),
//   )(data)
// }

// fn decode_object_as_list(
//   data: Dynamic,
//   inner: dynamic.Decoder(t),
// ) -> Result(List(#(String, t)), List(dynamic.DecodeError)) {
//   dynamic.dict(dynamic.string, inner)(data)
//   |> result.map(dict.to_list)
// }

// fn decode_array(
//   items: Dynamic,
//   data: Dict(String, Dynamic),
// ) -> Result(Schema, List(dynamic.DecodeError)) {
//   use nullable <- result.try(get_nullable(data))
//   use metadata <- result.try(get_metadata(data))
//   decode_schema(items)
//   |> push_path("items")
//   |> result.map(Array(nullable, metadata, _))
// }

// fn decode_one_of(
//   schemas: Dynamic,
//   data: Dict(String, Dynamic),
// ) -> Result(Schema, List(dynamic.DecodeError)) {
//   use nullable <- result.try(get_nullable(data))
//   use metadata <- result.try(get_metadata(data))
//   use schemas <- result.try(
//     dynamic.list(decode_schema)(schemas)
//     |> push_path("oneOf"),
//   )
//   Ok(OneOf(nullable, metadata, schemas))
// }

// fn decode_all_of(
//   schemas: Dynamic,
//   data: Dict(String, Dynamic),
// ) -> Result(Schema, List(dynamic.DecodeError)) {
//   use nullable <- result.try(get_nullable(data))
//   use metadata <- result.try(get_metadata(data))
//   use schemas <- result.try(
//     dynamic.list(decode_schema)(schemas)
//     |> push_path("allOf"),
//   )
//   Ok(AllOf(nullable, metadata, schemas))
// }

// fn decode_any_of(
//   schemas: Dynamic,
//   data: Dict(String, Dynamic),
// ) -> Result(Schema, List(dynamic.DecodeError)) {
//   use nullable <- result.try(get_nullable(data))
//   use metadata <- result.try(get_metadata(data))
//   use schemas <- result.try(
//     dynamic.list(decode_schema)(schemas)
//     |> push_path("anyOf"),
//   )
//   Ok(AnyOf(nullable, metadata, schemas))
// }

// fn decode_not(
//   schema: Dynamic,
//   data: Dict(String, Dynamic),
// ) -> Result(Schema, List(dynamic.DecodeError)) {
//   use nullable <- result.try(get_nullable(data))
//   use metadata <- result.try(get_metadata(data))
//   use schema <- result.try(
//     decode_schema(schema)
//     |> push_path("not"),
//   )
//   Ok(Not(nullable, metadata, schema))
// }

// fn decode_type(
//   type_: Dynamic,
//   data: Dict(String, Dynamic),
// ) -> Result(Schema, List(dynamic.DecodeError)) {
//   use type_ <- result.try(
//     dynamic.string(type_)
//     |> result.lazy_or(fn() {
//       dynamic.list(dynamic.string)(type_)
//       |> result.map(fn(types) {
//         case types {
//           [t] -> t
//           _ -> "object"
//           // Handle multiple types by defaulting to object
//         }
//       })
//     })
//     |> push_path("type"),
//   )
//   use nullable <- result.try(get_nullable(data))
//   use metadata <- result.try(get_metadata(data))

//   case type_ {
//     "boolean" -> Ok(Type(nullable, metadata, Boolean))
//     "string" -> Ok(Type(nullable, metadata, String))
//     "number" -> Ok(Type(nullable, metadata, Number))
//     "integer" -> Ok(Type(nullable, metadata, Integer))
//     "array" -> Ok(Type(nullable, metadata, ArrayType))
//     "object" -> Ok(Type(nullable, metadata, ObjectType))
//     "null" -> Ok(Type(nullable, metadata, Null))
//     _ -> Error([dynamic.DecodeError("Type", "String", ["type"])])
//   }
// }

// fn decode_enum(
//   variants: Dynamic,
//   data: Dict(String, Dynamic),
// ) -> Result(Schema, List(dynamic.DecodeError)) {
//   use nullable <- result.try(get_nullable(data))
//   use metadata <- result.try(get_metadata(data))
//   dynamic.list(dynamic.string)(variants)
//   |> push_path("enum")
//   |> result.map(Enum(nullable, metadata, _))
// }

// fn decode_ref(
//   ref: Dynamic,
//   data: Dict(String, Dynamic),
// ) -> Result(Schema, List(dynamic.DecodeError)) {
//   use nullable <- result.try(get_nullable(data))
//   use metadata <- result.try(get_metadata(data))
//   dynamic.string(ref)
//   |> push_path("$ref")
//   |> result.map(Ref(nullable, metadata, _))
// }

// fn decode_empty(
//   data: Dict(String, Dynamic),
// ) -> Result(Schema, List(dynamic.DecodeError)) {
//   use metadata <- result.try(get_metadata(data))
//   Ok(Empty(metadata:))
//   // case dict.size(data) {
//   //   0 -> Ok(Empty(metadata:))
//   //   _ -> Error([dynamic.DecodeError("Schema", "Dict", [])])
//   // }
// }

// fn push_path(
//   result: Result(t, List(dynamic.DecodeError)),
//   segment: String,
// ) -> Result(t, List(dynamic.DecodeError)) {
//   result.map_error(
//     result,
//     list.map(_, fn(e) { dynamic.DecodeError(..e, path: [segment, ..e.path]) }),
//   )
// }

// fn get_metadata(
//   data: Dict(String, Dynamic),
// ) -> Result(List(#(String, Dynamic)), List(dynamic.DecodeError)) {
//   let ignored_keys =
//     set.from_list([
//       "type", "enum", "$ref", "items", "properties", "required",
//       "additionalProperties", "patternProperties", "oneOf", "anyOf", "allOf",
//       "not", "$defs", "definitions", "nullable",
//     ])

//   let extract_metadata = fn(acc, key, value) {
//     case set.contains(ignored_keys, key) {
//       True -> acc
//       False -> [#(key, value), ..acc]
//     }
//   }

//   let metadata = dict.fold(data, [], extract_metadata)
//   Ok(metadata)
// }

// fn get_nullable(
//   data: Dict(String, Dynamic),
// ) -> Result(Bool, List(dynamic.DecodeError)) {
//   // Check for explicit "nullable" property
//   case dict.get(data, "nullable") {
//     Ok(data) -> dynamic.bool(data) |> push_path("nullable")
//     Error(_) -> {
//       // Check if type array includes "null"
//       case dict.get(data, "type") {
//         Ok(type_value) -> {
//           case dynamic.list(dynamic.string)(type_value) {
//             Ok(types) -> Ok(list.contains(types, "null"))
//             Error(_) -> Ok(False)
//           }
//         }
//         Error(_) -> Ok(False)
//       }
//     }
//   }
// }

// fn metadata_value_to_json(data: Dynamic) -> Json {
//   let decoder =
//     dynamic.any([
//       fn(a) { dynamic.string(a) |> result.map(json.string) },
//       fn(a) { dynamic.int(a) |> result.map(json.int) },
//       fn(a) { dynamic.float(a) |> result.map(json.float) },
//       fn(a) { dynamic.bool(a) |> result.map(json.bool) },
//     ])
//   case decoder(data) {
//     Ok(data) -> data
//     Error(_) -> json.string(string.inspect(data))
//   }
// }

// fn add_metadata(
//   data: List(#(String, Json)),
//   metadata: List(#(String, Dynamic)),
// ) -> List(#(String, Json)) {
//   list.fold(metadata, data, fn(acc, meta) {
//     [#(meta.0, metadata_value_to_json(meta.1)), ..acc]
//   })
// }

// fn add_nullable(
//   data: List(#(String, Json)),
//   nullable: Bool,
// ) -> List(#(String, Json)) {
//   case nullable {
//     False -> data
//     True -> [#("nullable", json.bool(True)), ..data]
//   }
// }
