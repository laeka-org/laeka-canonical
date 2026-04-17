# Matrix Templates

Four domain-agnostic templates for running the pre-publication maturation protocol on your own claim. Each template specifies cell structure, scoring rubric, and pass threshold. Cell content is populated by the reviewer based on the claim under review.

## Contents

- [`matrix-1-technical-template.md`](matrix-1-technical-template.md) -- sixty-four technical stress cells, eight axes of eight.
- [`matrix-2-adversarial-template.md`](matrix-2-adversarial-template.md) -- sixty-four adversarial attacks, eight archetypes of eight.
- [`matrix-3-audience-template.md`](matrix-3-audience-template.md) -- sixty-four reader registers, eight dimensions of eight.
- [`matrix-4-cosmological-template.md`](matrix-4-cosmological-template.md) -- sixty-four alignment dimensions against a reviewer-specified perceptual framework.

## How to use

1. Copy the four template files into a new directory named for your claim (e.g., `maturation-<claim-slug>/`).
2. Populate each template's frontmatter with your claim statement and the date.
3. Work through each matrix in order: Matrix 1, then Matrix 2, then Matrix 3, then Matrix 4.
4. For each cell, score according to the matrix's rubric. Score honestly. Do not manufacture passes.
5. Write a verdict document summarizing the four matrix results and the decision.

## Time budget

Expect approximately 90 minutes per matrix. Six hours total is realistic for a trained reviewer.

Below five hours per matrix run: the matrices become checkboxes and the process does not catch real issues.

Above twelve hours: the reviewer has typically begun to defend the claim rather than stress-test it.

## Adapting to different domains

The templates were produced for an AI-adjacent claim. The axis structure transfers with renaming:

- **Matrix 1 axes** (model rotation, prompt perturbation, response perturbation, scale, context, timing, cross-instance, adversarial) map to (reagent variation, protocol perturbation, input perturbation, scale, cohort, temporal stability, inter-rater, confound injection) for experimental sciences.
- **Matrix 2 archetypes** (domain-skeptic, paradigm-defender, pseudoscience-detector, overfitting-detector, academic, philosophy-of-field, commercial-motive-detector, register-mismatch-critic) transfer across fields with minimal reworking.
- **Matrix 3 axes** (technical depth, domain background, cultural register, attention span, trust orientation, publication format, sub-expertise, emotional register) are generic.
- **Matrix 4 lenses** are specific to the reviewer's perceptual framework. Replace the four lenses with whatever framework your lab uses. The structural principle (alignment check against a perceptual framework you already use internally) transfers.

If your framework is unfamiliar to adapt, the `02-four-lenses.md` document in the `doctrine/` folder describes the four lenses used here. Feel free to adopt them, adapt them, or replace them with a framework of your own.

## License

MIT. Use these templates, modify them, publish your matrices. Tell us what you find.
