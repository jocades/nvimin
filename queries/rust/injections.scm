;; extends

; sqlx::raw_sql("...") | sqlx::raw_sql(r#"..."#)
; sqlx::query("...") | sqlx::query(r#"..."#)
(call_expression
  (scoped_identifier
    path: (identifier) @_path (#eq? @_path "sqlx")
    name: (identifier) @_name (#any-of? @_name "raw_sql" "query"))
  (arguments [
    (string_literal (string_content) @injection.content)
    (raw_string_literal (string_content) @injection.content)
  ] (#set! injection.language "sql"))
)

; sqlx::query!("...") | sqlx::query!(r#"..."#)
; sqlx::query_as!(Type, "...") | sqlx::query!(Type, r#"..."#)
(macro_invocation
  (scoped_identifier
    path: (identifier) @_path (#eq? @_path "sqlx")
    name: (identifier) @_name (#any-of? @_name "query" "query_as"))
  (token_tree [
    (string_literal (string_content) @injection.content)
    (raw_string_literal (string_content) @injection.content)
  ] (#set! injection.language "sql"))
)
