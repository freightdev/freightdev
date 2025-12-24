# zBox

## Overview
zBox is a modern **Zsh environment loader** that manages KEY:VALUE environment variables, dotfiles, and modular function/settings scaffolds.  
It was developed and is maintained by **Jesse E.E.W. Conley**.  

Released under the **MIT License**, meaning you are free to use, modify, and distribute it with minimal restrictions.

---

## Installation

Clone the repository:

```zsh
git clone https://github.com/freightdev/zbox.git
````

Quick run:

```zsh
git clone https://github.com/freightdev/zbox.git | zsh
```

---

## Usage via CLI

* `zbox setup` → Full setup (init | repo | env)
* `zbox init` → System initialization only
* `zbox repo` → Custom git repo setup only
* `zbox env` → Custom environment setup only

### Flags

* `--force, -f` → Ignore checks and force execution
* `--interactive, -i` → Run in full interactive mode (recommended)

---

## Requirements

* **Keys** must exist in:
```zsh
    $HOME/.zbox/.envs/keys
```
* **Defaults** should be set up in:
```zsh
    $HOME/.zbox/.envs/.env.defaults
```
* **Packages** for initialization are defined in:
```zsh
    $HOME/.zbox/src/configs/setup-pkgs.conf
```

---

## Development

Pull requests and contributions are welcome.
Please fork the repo, create a branch, and open a PR.

---

## License

This project is licensed under the [MIT License](LICENSE).

---

## 👤 Author

**Jesse Edward Eugene Wayne Conley**

* 📬 [jesse.freightdev@gmail.com](mailto:jesse.freightdev@gmail.com)
* 🔗 [github.com/freightdev](https://github.com/freightdev)
* 🤗 [huggingface.co/freightdev](https://huggingface.co/freightdev)
* 🔌 [x.com/freightdevjesse](https://x.com/freightdevjesse)
* 💏 [linkedin.com/in/freightdevjesse](https://linkedin.com/in/freightdevjesse)

---

## 💛 Support the Mission

If this inspires your build, saves you time, or helps your agents run smarter:

**☕ [Buy Me a Coffee](https://coff.ee/freightdev)**
Every dollar supports the tools made for the ones still behind the wheel.

> Built with calloused hands, sleepless nights, and way too much coffee.
>
> — Jesse E.E.W. Conley 🚚💻☕
