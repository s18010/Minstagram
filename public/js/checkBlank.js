// const checkNull = (id) => {
//   if (document.getElementById(id).value === "" || !(document.getElementById(id).value))  {
//       document.getElementById("submit").setAttribute("disabled", "true");
//       document.getElementById("warning").classList.add("warning");
//   } else {
//     document.getElementById("submit").removeAttribute("disabled", "true");
//     document.getElementById("warning").classList.remove("warning");
//   }
// }
//
// document.forms[0].addEventListener("keyup", checkNull("name"), false);

// 入力されていない項目があったらsubmitできないようにする
const name = document.getElementById('name')
const email = document.getElementById('email')
const comment = document.getElementById('comment')

function checkNull() {
  const contents = [name.value, email.value, comment.value]

  let temp = contents
  temp.forEach(content => {
    while (content.match(" ")) {
      content = content.replace(" ", "")
    };
    if (content == "") {
      document.getElementById("submit").setAttribute("disabled", "true");
      document.getElementById("submit").style.color="red";
    } else {
      document.getElementById("submit").removeAttribute("disabled", "true");
      document.getElementById("submit").style.color="white";
    }
  });
}

document.forms[0].addEventListener("keyup", checkNull, false);
