#------------------------------ [listname]: list alias created [date]
[IF is_default_domain]
[listname]: "| [path_to_queue] [listname]@[domain]"
[listname]-request: "| [path_to_queue] [listname]-request@[domain]"
[listname]-editor: "| [path_to_queue] [listname]-editor@[domain]"
#[listname]-subscribe: "| [path_to_queue] [listname]-subscribe@[domain]"
[listname]-unsubscribe: "| [path_to_queue] [listname]-unsubscribe@[domain]"
[listname]-owner: "| [path_to_bouncequeue] [listname]-unsubscribe@[domain]"
[ELSE]
[domain]-[listname]: "| [path_to_queue] [listname]@[domain]"
[domain]-[listname]-request: "| [path_to_queue] [listname]-request@[domain]"
[domain]-[listname]-editor: "| [path_to_queue] [listname]-editor@[domain]"
#[domain]-[listname]-subscribe: "| [path_to_queue] [listname]-subscribe@[domain]"
[domain]-[listname]-unsubscribe: "| [path_to_queue] [listname]-unsubscribe@[domain]"
[domain]-[listname]-owner: "| [path_to_bouncequeue] [listname]-unsubscribe@[domain]"
[ENDIF]