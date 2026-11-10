import { AfterViewInit, Component, ElementRef, OnDestroy, input, output, viewChild } from '@angular/core';
import lottie, { AnimationItem } from 'lottie-web';

// Animación de Lottie con los mismos JSON que Android. Al salir se destruye y deja de gastar procesador
@Component({
  selector: 'app-lottie',
  standalone: true,
  template: `<div #caja class="caja"></div>`,
  styles: [`:host { display: block; } .caja { width: 100%; height: 100%; }`],
})
export class LottieComponent implements AfterViewInit, OnDestroy {
  nombre = input.required<'cargando' | 'hecho'>();
  bucle = input(true);
  terminada = output<void>();

  private caja = viewChild.required<ElementRef<HTMLDivElement>>('caja');
  private animacion?: AnimationItem;

  ngAfterViewInit(): void {
    this.animacion = lottie.loadAnimation({
      container: this.caja().nativeElement,
      renderer: 'svg',                                   // vectores: ligero y nítido
      loop: this.bucle(),
      autoplay: true,
      path: `assets/lottie/${this.nombre()}.json`,       // los mismos JSON que Android (res/raw)
    });
    this.animacion.addEventListener('complete', () => this.terminada.emit());
  }

  ngOnDestroy(): void {
    this.animacion?.destroy();                           // libera la animación
  }
}
