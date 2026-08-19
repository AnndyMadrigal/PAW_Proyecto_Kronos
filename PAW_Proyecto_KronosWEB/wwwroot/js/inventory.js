$(document).ready(function () {

    // ==========================================
    // 1. LÓGICA DE TABLA DE INVENTARIO (INDEX)
    // ==========================================
    if ($("#inventoryTableBody").length) {
        const rows = Array.from(document.querySelectorAll('.inventory-row'));
        const searchInput = document.getElementById('searchInput');
        const categoryFilter = document.getElementById('categoryFilter');
        const itemCountEl = document.getElementById('itemCount');
        const totalCountEl = document.getElementById('totalCount');
        const btnPrev = document.getElementById('btnPrevious');
        const btnNext = document.getElementById('btnNext');

        let currentPage = 1;
        const itemsPerPage = 20;
        let matchingRows = [...rows];

        function applyFilters() {
            const searchVal = (searchInput?.value || '').trim().toLowerCase();
            const catVal = categoryFilter?.value || '';

            matchingRows = rows.filter(row => {
                const searchAttr = row.getAttribute('data-search') || '';
                const catAttr = row.getAttribute('data-category') || '';

                const matchesSearch = !searchVal || searchAttr.includes(searchVal);
                const matchesCat = !catVal || catAttr === catVal;

                return matchesSearch && matchesCat;
            });

            currentPage = 1;
            renderPage();
        }

        function renderPage() {
            const total = matchingRows.length;
            const maxPages = Math.max(1, Math.ceil(total / itemsPerPage));
            if (currentPage > maxPages) currentPage = maxPages;

            const start = (currentPage - 1) * itemsPerPage;
            const end = start + itemsPerPage;

            rows.forEach(r => r.style.display = 'none');

            matchingRows.slice(start, end).forEach(r => {
                r.style.display = '';
            });

            if (itemCountEl) itemCountEl.textContent = Math.min(end, total);
            if (totalCountEl) totalCountEl.textContent = total;

            if (btnPrev) btnPrev.disabled = currentPage <= 1;
            if (btnNext) btnNext.disabled = currentPage >= maxPages;
        }

        if (searchInput) {
            searchInput.addEventListener('input', applyFilters);
        }

        if (categoryFilter) {
            categoryFilter.addEventListener('change', applyFilters);
        }

        if (btnPrev) {
            btnPrev.addEventListener('click', function () {
                if (currentPage > 1) {
                    currentPage--;
                    renderPage();
                }
            });
        }

        if (btnNext) {
            btnNext.addEventListener('click', function () {
                const maxPages = Math.ceil(matchingRows.length / itemsPerPage);
                if (currentPage < maxPages) {
                    currentPage++;
                    renderPage();
                }
            });
        }

        renderPage();
    }

    // ==========================================
    // 2. VALIDACIÓN FORMULARIO CREAR PRODUCTO
    // ==========================================
    if ($("#createInventoryForm").length) {
        $("#createInventoryForm").validate({
            rules: {
                name: {
                    required: true,
                    minlength: 2,
                    maxlength: 200
                },
                description: {
                    maxlength: 500
                },
                inventory_category_id: {
                    required: true
                },
                inventory_unit_id: {
                    required: true
                },
                minimum_stock: {
                    required: true,
                    number: true,
                    min: 0
                }
            },
            messages: {
                name: {
                    required: "Por favor, ingresa el nombre del producto.",
                    minlength: "El nombre debe tener al menos 2 caracteres.",
                    maxlength: "El nombre no puede exceder 200 caracteres."
                },
                description: {
                    maxlength: "La descripción no puede exceder 500 caracteres."
                },
                inventory_category_id: {
                    required: "Por favor, selecciona una categoría."
                },
                inventory_unit_id: {
                    required: "Por favor, selecciona una unidad de medida."
                },
                minimum_stock: {
                    required: "Por favor, ingresa el stock mínimo.",
                    number: "Por favor, ingresa un número válido.",
                    min: "El stock mínimo no puede ser negativo."
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

    // ==========================================
    // 3. VALIDACIÓN FORMULARIO EDITAR PRODUCTO
    // ==========================================
    if ($("#editInventoryForm").length) {
        $("#editInventoryForm").validate({
            rules: {
                name: {
                    required: true,
                    minlength: 2,
                    maxlength: 200
                },
                description: {
                    maxlength: 500
                },
                inventory_category_id: {
                    required: true
                },
                inventory_unit_id: {
                    required: true
                },
                minimum_stock: {
                    required: true,
                    number: true,
                    min: 0
                }
            },
            messages: {
                name: {
                    required: "Por favor, ingresa el nombre del producto.",
                    minlength: "El nombre debe tener al menos 2 caracteres.",
                    maxlength: "El nombre no puede exceder 200 caracteres."
                },
                description: {
                    maxlength: "La descripción no puede exceder 500 caracteres."
                },
                inventory_category_id: {
                    required: "Por favor, selecciona una categoría."
                },
                inventory_unit_id: {
                    required: "Por favor, selecciona una unidad de medida."
                },
                minimum_stock: {
                    required: "Por favor, ingresa el stock mínimo.",
                    number: "Por favor, ingresa un número válido.",
                    min: "El stock mínimo no puede ser negativo."
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
