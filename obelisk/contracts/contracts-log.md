20260309-0100 | Account Import — Create Group When Old Account Missing | UPDATE
Old: "Rows where the old account is not found, the new account already exists, or required cell values are invalid are skipped."
New: If old account doesn't exist and new account also doesn't exist → create new subscriber group, insert both accounts. If old account doesn't exist but new account exists → add old account to new's group; new is not re-inserted. Old-exists cases are unchanged.
