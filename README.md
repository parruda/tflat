# TFlat = Terraform + Subdirectories + Ruby (ERB)

Aren't you tired of copy and pasting?

I love [Terraform](https://www.terraform.io/), but HCL really gets in the way sometimes.

How many times you wish you could just write a simple IF or CASE statement inside a `.tf` file? Any attempt of having minimal flow control with HCL results in a massive oneliner mess. Sometimes it feels like writing PERL one-liners. Hard to read equals hard to debug.

Also, you can't use subfolders with Terraform, so you often end up at one of the three scenarios below:
- You have a few `.tf` files with a lot of code in it. Ugly and not organized.
- You create lots of different `.tf` files in a single directory, which makes it really hard to stay organized.
- You separate everything in modules, so you have to keep passing variables downstream. And if you try to be **DRY**, good luck passing 1 million variables downstream to submodules!

TFlat does 2 things to solve this problem:
* Separate your Terraform code in subdirectories.
* It allows you to write Ruby code in `.tf` files using ERB templates. Hurray!

Jump to:
* [Installation](#installation)
* [Usage](#usage)


## How does TFlat make Terraform read subdirectories?
It doesn't. This is what happens when you run it:
1. Create a folder `.tflat` inside the current folder if it doesn't exist yet. If it does exist, delete all files from this folder non-recursively.
2. Make a recursive list of all files in the current directory and move one by one to the `.tflat` folder.
3. Replace all non-binary files in `.tflat/` with its ERB rendered version.
4. Execute `terraform` with the arguments you passed to `tflat`.

For example, say you have the following file structure:
```
|_ config
  |_ providers.tf
  |_ state.tf
|_ ec2
  |_ files
    |_ user_data.sh
  |_ instances.tf
  |_ keypairs.tf
|_ outputs.tf
|_ variables.tf
```
TFlat will create the following files inside `./.tflat/`

```
config#providers.tf
config#state.tf
ec2#files#user_data.sh
ec2#instances.tf
ec2#keypairs.tf
outputs.tf
variables.tf
```

Then it will `cd` into `.tflat` and run `terraform` with the arguments you passed to `tflat`.

**IMPORTANT:** The `.terraform` folder will live at `.tflat/.terraform`, so make sure you don't delete that folder if you are storing the terraform state locally!

There's only one more thing you have to pay attention to: handling file references.

### Handling file references
Because TFlat will actually copy and rename files to make it work with subdirectories, you need to pass file references in a different way. For example, imagine you are rendering a terraform template like this:

files/userdata.tpl
```
#!/bin/bash
# ...
CONSUL_ADDRESS=${consul_address}
# ...
```
main.tf
```
# ...
data "template_file" "ec2_userdata" {
  template = "${file("files/userdata.tpl")}"

  vars {
    consul_address = "${aws_instance.consul.private_ip}"
  }
}

# Create a web server
resource "aws_instance" "web" {
  # ...

  user_data = "${data.template_file.ec2_userdata.rendered}"
}
# ...
```

The line `template = "${file("files/userdata.tpl")}"` has to be written the in one of the following ways to work with TFlat:

```
# Let Ruby load the file content using the 'file' helper method (easier to read)
template = "<%= file('files/userdata.tpl') %>"

# Let Terraform load the file content using the 'f' helper method (quoting nightmare!)
template = "${file("<%= f('files/userdata.tpl') %>")}"
```

**IMPORTANT:** The file path must be relative to the project's root folder!

It is up to you to choose what you like. Try both and look inside `.tflat/main.tf` to see the difference between the two ways.

## Installation
1. [Download and install Terraform](https://www.terraform.io/intro/getting-started/install.html). Make sure the `terraform` command is in your **$PATH**.

2. Install the gem:
```
$ gem install tflat
```

## Usage
TFlat takes the same arguments from Terraform. It actually hands off the execution to Terraform after processing the files. So:

```
terraform plan
```
Becomes:
```
tflat plan
```
That's it!


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/parruda/tflat. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
