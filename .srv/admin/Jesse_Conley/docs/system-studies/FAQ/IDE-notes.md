## File Content 🗂️

This is the actual code or text in the current file you’re editing.
Your assistant uses it to understand what’s going on:

    Function definitions

    Imports

    Current file scope

    Comments

    ✅ Example:
    If you’re editing a file with a function handle_user_login, the assistant knows what’s already written and doesn’t repeat it.

## Cursor Position ➡️🖱️

This is where your cursor is in the file. It’s critical because it defines what kind of help you probably need.

    If the cursor is inside a function → suggest completion

    If it’s at the top of a file → maybe suggest imports or docstrings

    If it’s on an error line → suggest a fix

    ✅ Example:
    Cursor is here:

    fn add_user() {
        let user =
                 ^ cursor here
    }

    The assistant can now suggest: User::new(name, email) because it knows the context around the cursor.

## Prompt Type 💬

This defines what kind of help you’re asking for, or what the assistant thinks you want based on cursor + file content.

Types could include:
Prompt Type	Description
✍️ completion	Suggest the next few tokens/lines
🛠️ fix	Suggest a fix for an error or warning
🧪 generate test	Write a test for the selected function
🧹 refactor	Clean up or improve the selected code
📄 doc	Generate a docstring or comment block
🔁 rewrite	Rewrite code based on your comment
💡 explain	Explain what this code does in simple terms

✅ Example:
If you're on a function and run a "doc" prompt type, it will output:

    /// Adds a new user to the system based on provided info

🔧 How This All Comes Together (like in Cursor or Codriver)

When you hit a hotkey:

    It grabs the code around the cursor

    It reads what you're asking for (prompt type)

    It sends all that to the model (like GPT or a local LLM)

    You get back something relevant — completion, fix, doc, etc.
