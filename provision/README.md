# Ansible provisioning

The provisioning is based on a list of public roles listed in `requirements.yml`.
These roles will be automatically downloaded by Ansible right after the VM first boot.

You can customize the provisioning by modifying the following files :
- vars/all/main.yml : fill in your personnal information
- vars/all/tools.yml : choose the tools you want and how they are configured
- files/bookmarks.html : override this file with your own chrome bookmarks
- files/wallpaper.jpg : override this file with your own wallpaper
- files/zsh_aliases : override this file with your own zsh_aliases
- files/zshrc : override this file with your own zshrc file

# Enhancements

- The playbook is not completely idempotent because of the behaviour of a few imported roles.
It could be by using local copies of the concerned roles.

- Only chrome bookmarks can be imported automatically. It is unfortunately not possible to do it the same way for Firefox so bookmarks must be imported manually.