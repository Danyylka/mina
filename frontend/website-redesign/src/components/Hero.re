open Css;

module Styles = {
  let heroContainer = (backgroundImg: Theme.backgroundImage) =>
    style([
      display(`flex),
      flexDirection(`column),
      justifyContent(`flexStart),
      alignContent(`spaceBetween),
      backgroundImage(`url(backgroundImg.mobile)),
      backgroundSize(`cover),
      media(
        Theme.MediaQuery.tablet,
        [backgroundImage(`url(backgroundImg.tablet))],
      ),
      media(
        Theme.MediaQuery.desktop,
        [backgroundImage(`url(backgroundImg.desktop))],
      ),
    ]);
  let heroContent =
    style([
      marginTop(`rem(4.2)),
      marginBottom(`rem(1.9)),
      marginLeft(`rem(1.25)),
      media(
        Theme.MediaQuery.tablet,
        [
          marginTop(`rem(7.)),
          marginBottom(`rem(6.5)),
          marginLeft(`rem(2.5)),
        ],
      ),
      media(
        Theme.MediaQuery.desktop,
        [
          marginTop(`rem(17.1)),
          marginBottom(`rem(8.)),
          marginLeft(`rem(9.5)),
        ],
      ),
    ]);
  let headerLabel =
    merge([
      Theme.Type.label,
      style([color(black), marginTop(`zero), marginBottom(`zero)]),
    ]);
  let header =
    merge([
      Theme.Type.h1,
      style([
        unsafe("width", "max-content"),
        backgroundColor(white),
        marginRight(`rem(1.)),
        fontSize(`rem(1.5)),
        padding2(~v=`rem(1.3), ~h=`rem(1.3)),
        media(
          Theme.MediaQuery.desktop,
          [padding2(~v=`rem(1.5), ~h=`rem(1.5))],
        ),
        marginTop(`rem(1.)),
        marginBottom(`rem(1.5)),
      ]),
    ]);
  let headerCopy =
    merge([
      Theme.Type.pageSubhead,
      style([
        backgroundColor(white),
        padding2(~v=`rem(1.5), ~h=`rem(1.5)),
        marginRight(`rem(1.)),
        media(Theme.MediaQuery.tablet, [width(`rem(34.))]),
        marginTop(`zero),
        marginBottom(`zero),
      ]),
    ]);
};

/**
 * This component takes in three different background images, as per Mina's design.
 */

[@react.component]
let make =
    (~title, ~header, ~copy, ~background: Theme.backgroundImage, ~children=?) => {
  <div className={Styles.heroContainer(background)}>
    <div className=Styles.heroContent>
      <h4 className=Styles.headerLabel> {React.string(title)} </h4>
      <h1 className=Styles.header> {React.string(header)} </h1>
      <p className=Styles.headerCopy> {React.string(copy)} </p>
      {switch (children) {
       | Some(children) => children
       | None => React.null
       }}
    </div>
  </div>;
};
