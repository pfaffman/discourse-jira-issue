export default function() {
  this.route("jira-issue", function() {
    this.route("actions", function() {
      this.route("show", { path: "/:id" });
    });
  });
};
