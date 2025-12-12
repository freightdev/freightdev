interface Props {
  title: string;
  description?: string;
}

const {
  title,
  description = "HWY-TMS - Highway Transportation Management System by Fast & Easy Dispatching LLC",
} = Astro.props;