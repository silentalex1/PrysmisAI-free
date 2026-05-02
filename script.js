function toggleFaq(element) {
  const item = element.parentElement;
  item.classList.toggle('active');
}

document.addEventListener('DOMContentLoaded', function () {
  const faqItems = document.querySelectorAll('.faq-item');
  
  faqItems.forEach(function(item) {
    const header = item.querySelector('.faq-header');
    header.addEventListener('click', function() {
      faqItems.forEach(function(otherItem) {
        if (otherItem !== item) {
          otherItem.classList.remove('active');
        }
      });
    });
  });
});