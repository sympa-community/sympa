[IF domain_is_default_domain]
[listname]: "| [path_to_queue] [listname]@[domain]"
[listname]-request: "| [path_to_queue] [listname]-request@[domain]"
[listname]-editor: "| [path_to_queue] [listname]-editor@[domain]"
#[listname]-subscribe: "| [path_to_queue] [listname]-subscribe@[domain]"
[listname]-unsubscribe: "| [path_to_queue] [listname]-unsubscribe@[domain]"
[listname]-owner: "| [path_to_bouncequeue] [listname]-unsubscribe@[domain]"
[ELSE]
[DOMAIN]-[listname]: "| [path_to_queue] [listname]@[domain]"
[DOMAIN]-[listname]-request: "| [path_to_queue] [listname]-request@[domain]"
[DOMAIN]-[listname]-editor: "| [path_to_queue] [listname]-editor@[domain]"
#[DOMAIN]-[listname]-subscribe: "| [path_to_queue] [listname]-subscribe@[domain]"
[DOMAIN]-[listname]-unsubscribe: "| [path_to_queue] [listname]-unsubscribe@[domain]"
[DOMAIN]-[listname]-owner: "| [path_to_bouncequeue] [listname]-unsubscribe@[domain]"
[ENDIF]