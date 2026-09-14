document.addEventListener("click", function (event) {
  document.querySelectorAll("details[data-dropdown][open]").forEach(function (details) {
    if (!details.contains(event.target)) details.open = false;
  });
});

document.addEventListener("click", function (event) {
  var button = event.target.closest("[data-copy]");
  if (!button) return;

  navigator.clipboard.writeText(button.dataset.copy).then(function () {
    var original = button.textContent;
    button.textContent = "Copied!";
    setTimeout(function () { button.textContent = original; }, 1500);
  });
});
