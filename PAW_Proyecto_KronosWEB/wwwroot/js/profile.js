$(document).ready(function () {

    // Validaciones para el formulario de Cambio de Contraseña
    if ($("#ChangePasswordForm").length) {
        $("#ChangePasswordForm").validate({
            rules: {
                password: {
                    required: true,
                    minlength: 6
                },
                confirmPassword: {
                    required: true,
                    equalTo: "#password"
                }
            },
            messages: {
                password: {
                    required: "Por favor, ingresa tu nueva contraseña.",
                    minlength: "La contraseña debe tener al menos 6 caracteres."
                },
                confirmPassword: {
                    required: "Por favor, confirma tu nueva contraseña.",
                    equalTo: "Las contraseñas no coinciden."
                }
            },
            errorElement: "span",
            errorPlacement: function (error, element) {
                error.addClass("text-xs text-red-500 mt-1 block");

                if (element.parent().hasClass("relative")) {
                    error.insertAfter(element.parent());
                } else {
                    error.insertAfter(element);
                }
            },
            highlight: function (element) {
                $(element)
                    .addClass("border-red-500 focus:border-red-500 focus:ring-red-500/10")
                    .removeClass("border-gray-300 dark:border-gray-700 focus:border-brand-500 focus:ring-brand-500/20");
            },
            unhighlight: function (element) {
                $(element)
                    .removeClass("border-red-500 focus:border-red-500 focus:ring-red-500/10")
                    .addClass("border-gray-300 dark:border-gray-700 focus:border-brand-500 focus:ring-brand-500/20");
            },
            submitHandler: function (form) {
                form.submit();
            }
        });
    }

    // Validaciones para el formulario de Información de Perfil
    if ($("#ProfileForm").length) {
        $("#ProfileForm").validate({
            rules: {
                username: {
                    required: true,
                    minlength: 3
                },
                full_name: {
                    required: true,
                    minlength: 6
                },
                phone: {
                    required: true,
                    minlength: 8
                }
            },
            messages: {
                username: {
                    required: "Por favor, ingresa un nombre de usuario.",
                    minlength: "El usuario debe tener al menos 3 caracteres."
                },
                full_name: {
                    required: "Por favor, ingresa tu nombre completo.",
                    minlength: "El nombre debe tener al menos 3 caracteres."
                },
                phone: {
                    required: "Por favor, ingresa tu teléfono.",
                    minlength: "El teléfono debe tener al menos 8 caracteres."
                }
            },
            errorElement: "span",
            errorPlacement: function (error, element) {
                error.addClass("text-xs text-red-500 mt-1 block");

                if (element.parent().hasClass("relative")) {
                    error.insertAfter(element.parent());
                } else {
                    error.insertAfter(element);
                }
            },
            highlight: function (element) {
                $(element)
                    .addClass("border-red-500 focus:border-red-500 focus:ring-red-500/10")
                    .removeClass("border-gray-300 dark:border-gray-700 focus:border-brand-500 focus:ring-brand-500/20");
            },
            unhighlight: function (element) {
                $(element)
                    .removeClass("border-red-500 focus:border-red-500 focus:ring-red-500/10")
                    .addClass("border-gray-300 dark:border-gray-700 focus:border-brand-500 focus:ring-brand-500/20");
            },
            submitHandler: function (form) {
                form.submit();
            }
        });
    }

});