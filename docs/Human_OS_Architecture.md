# Human OS Architecture

*Placeholder for architecture overview.*

This document is intended to describe the core components and design principles of the Human Operating System. Future sections should expand on system modules, data flow and integration guidelines.
## Row Level Security defaults

The core database enforces `ROW LEVEL SECURITY` on every application table. Each table includes an `org_uid` column and policies restrict access so that a session's `org_uid` claim must match the row's `org_uid`. Read and write permissions follow this pattern unless a table explicitly allows broader access.

See the migrations under `supabase/migrations` for exact policy definitions.
