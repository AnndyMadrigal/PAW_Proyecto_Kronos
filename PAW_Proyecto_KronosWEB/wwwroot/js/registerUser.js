$(document).ready(function () {
    // Configuración de jQuery Validate para el formulario
    $("#registerForm").validate({
        // Reglas de validación basadas en los atributos 'name' de tus inputs
        rules: {
            username: {
                required: true,
                minlength: 3
            },
            email: {
                required: true,
                email: true
            },
            full_name: {
                required: true,
                minlength: 5
            },
            phone: {
                required: true,
                digits: true, // Si solo permites números, si no, puedes cambiarlo o quitarlo
                minlength: 8
            },
            password: {
                required: true,
                minlength: 6
            }
        },

        // Mensajes de error personalizados en español
        messages: {
            username: {
                required: "Por favor, ingresa un nombre de usuario.",
                minlength: "El nombre de usuario debe tener al menos 3 caracteres."
            },
            email: {
                required: "Por favor, ingresa tu correo electrónico.",
                email: "Por favor, ingresa un formato de correo válido (ej: usuario@correo.com)."
            },
            full_name: {
                required: "Por favor, ingresa tu nombre completo.",
                minlength: "El nombre debe tener al menos 5 caracteres."
            },
            phone: {
                required: "Por favor, ingresa tu número de teléfono.",
                digits: "El teléfono solo debe contener números.",
                minlength: "Por favor, ingresa un número de teléfono válido."
            },
            password: {
                required: "Por favor, ingresa una contraseña.",
                minlength: "La contraseña debe tener al menos 6 caracteres."
            }
        },

        // Dónde colocar el mensaje de error para que no altere el diseño
        errorPlacement: function (error, element) {
            // Creamos un contenedor con estilos de Tailwind para el mensaje de error (texto rojo pequeño)
            error.addClass("text-xs text-red-500 mt-1 block");

            // Si el input está dentro de un contenedor relativo (como el de contraseña con Alpine), 
            // colocamos el error fuera de ese contenedor para que no se desplace el botón de ver contraseña
            if (element.parent().hasClass("relative")) {
                error.insertAfter(element.parent());
            } else {
                error.insertAfter(element);
            }
        },

        // Estilos visuales del Input cuando es INVÁLIDO
        highlight: function (element, errorClass, validClass) {
            $(element)
                .addClass("border-red-500 focus:border-red-500 focus:ring-red-500/10")
                .removeClass("border-gray-300 dark:border-gray-700 focus:border-brand-300 focus:ring-brand-500/10");
        },

        // Estilos visuales del Input cuando es VÁLIDO
        unhighlight: function (element, errorClass, validClass) {
            $(element)
                .removeClass("border-red-500 focus:border-red-500 focus:ring-red-500/10")
                .addClass("border-gray-300 dark:border-gray-700 focus:border-brand-300 focus:ring-brand-500/10");
        },

        // Qué hacer cuando el formulario es válido y se envía
        submitHandler: function (form) {
            // Permite que el formulario se envíe normalmente al controlador de ASP.NET Core
            form.submit();
        }
    });
});
